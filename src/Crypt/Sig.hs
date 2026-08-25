{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Crypt.Sig
  ( SigFile (..)
  , signFile
  , checkFile
  , saveSigFile
  , loadSigFile
  ) where

import Crypt.Hash (hashFile)
import Crypt
  ( PrivateKey
  , PublicKey
  , algoName 
  , sign
  , verify
  )
import Data.Aeson (FromJSON, ToJSON, encode, decode)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import GHC.Generics (Generic)

data SigFile = SigFile
  { sigHashAlg :: String        -- "BLAKE3"
  , sigSignAlg :: String        -- "Dilithium3"
  , sigDigest  :: BS.ByteString 
  , sigBytes   :: BS.ByteString
  } deriving (Show, Generic)

instance ToJSON SigFile
instance FromJSON SigFile

signFile :: PrivateKey -> FilePath -> IO SigFile
signFile priv path = do
  digest <- hashFile path
  sig <- sign priv digest
  pure SigFile
    { sigHashAlg = "BLAKE3"
    , sigSignAlg = algoName 
    , sigDigest  = digest
    , sigBytes   = sig
    }

checkFile :: PublicKey -> FilePath -> SigFile -> IO Bool
checkFile pub path sf = do
  digest <- hashFile path
  if digest /= sigDigest sf
    then pure False
    else verify pub digest (sigBytes sf)

saveSigFile :: FilePath -> SigFile -> IO ()
saveSigFile path sf = BSL.writeFile path (encode sf)

loadSigFile :: FilePath -> IO (Either String SigFile)
loadSigFile path = do
  content <- BSL.readFile path
  case decode content of
    Just sf -> pure $ Right sf
    Nothing -> pure $ Left "failed to parse signature file: invalid json or base64 data"
