{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

  module Crypt.Sig
( SigFile (..)
  , signFile
  , checkFile
  , saveSigFile
  , loadSigFile
  , sign
  , verify
  , encryptFile
  , decryptFile
  ) where

import Crypt.Hash (hashFile)
  import qualified Crypt as Dilithium
import Crypt (PrivateKey, PublicKey, algName)
  import qualified Crypt.AES as AES
  import Data.Aeson (FromJSON, ToJSON, encode, decode)
import Data.ByteString (ByteString)
  import qualified Data.ByteString.Base64 as B64
  import qualified Data.ByteString.Lazy as BSL
  import GHC.Generics (Generic)
import Data.Text (Text)
  import qualified Data.Text.Encoding as TE

  data SigFile = SigFile
{ sigHashAlg :: String        -- "BLAKE3"
  , sigSignAlg :: String        -- from Crypt.algName
    , sigDigest  :: Text          -- Base64(digest)
    , sigBytes   :: Text          -- Base64(signature)
} deriving (Show, Generic)

instance ToJSON SigFile
instance FromJSON SigFile

b64 :: ByteString -> Text
b64 = TE.decodeUtf8 . B64.encode

unb64 :: Text -> Either String ByteString
unb64 = B64.decode . TE.encodeUtf8

signFile :: PrivateKey -> FilePath -> IO SigFile
signFile priv path = do
digest <- hashFile path
sig <- Dilithium.sign priv digest
pure SigFile
{ sigHashAlg = "BLAKE3"
  , sigSignAlg = algName
    , sigDigest  = b64 digest
    , sigBytes   = b64 sig
}

checkFile :: PublicKey -> FilePath -> SigFile -> IO Bool
checkFile pub path sf = do
digest <- hashFile path
  case (unb64 (sigDigest sf), unb64 (sigBytes sf)) of
(Right storedDigest, Right sig)
  | digest == storedDigest -> Dilithium.verify pub digest sig
  _ -> pure False

  saveSigFile :: FilePath -> SigFile -> IO ()
saveSigFile path sf = BSL.writeFile path (encode sf)

loadSigFile :: FilePath -> IO (Either String SigFile)
  loadSigFile path = do
  content <- BSL.readFile path
  case decode content of
  Just sf -> pure $ Right sf
  Nothing -> pure $ Left "failed to parse signature file: invalid json or base64 data"

  sign :: PrivateKey -> FilePath -> IO SigFile
  sign priv path = do
  sf <- signFile priv path
  saveSigFile (path ++ ".asc") sf
  pure sf

verify :: PublicKey -> FilePath -> SigFile -> IO Bool
verify = checkFile

encryptFile :: PrivateKey -> AES.Key -> FilePath -> FilePath -> IO SigFile
encryptFile priv aesKey srcPath dstPath = do
  AES.encryptFile aesKey srcPath dstPath
  sign priv dstPath

decryptFile :: PublicKey -> AES.Key -> FilePath -> FilePath -> IO (Either String ())
decryptFile pub aesKey srcPath dstPath = do
  sfResult <- loadSigFile (srcPath ++ ".asc")
  case sfResult of
    Left err -> pure $ Left $ "no valid signature file: " ++ err
    Right sf -> do
      ok <- checkFile pub srcPath sf
      if not ok
        then pure $ Left "signature verification failed -- refusing to decrypt"
        else do
          AES.decryptFile aesKey srcPath dstPath
          pure $ Right ()
