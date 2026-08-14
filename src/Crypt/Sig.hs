{-# LANGUAGE DeriveGeneric #-}

module Crypt.Sig
  ( SigFile (..)
  , signFile
  , checkFile
  , saveSigFile
  , loadSigFile
  ) where

import Crypt.Hash (Digest, hashFile)
import Crypt.PQ
  ( PQPrivateKey
  , PQPublicKey
  , pqAlgorithmName
  , pqSign
  , pqVerify
  )
import Data.Binary (Binary (..), decode, encode)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import GHC.Generics (Generic)

data SigFile = SigFile
  { sigHashAlg :: String       -- BLAKE3
  , sigSignAlg :: String       -- Dilithium3
  , sigDigest  :: BS.ByteString
  , sigBytes   :: BS.ByteString
  } deriving (Show, Generic)

instance Binary SigFile

signFile :: PQPrivateKey -> FilePath -> IO SigFile
signFile priv path = do
  digest <- hashFile path
  sig <- pqSign priv digest
  pure SigFile
    { sigHashAlg = "BLAKE3"
    , sigSignAlg = pqAlgorithmName
    , sigDigest  = digest
    , sigBytes   = sig
    }

checkFile :: PQPublicKey -> FilePath -> SigFile -> IO Bool
checkFile pub path sf = do
  digest <- hashFile path
  if digest /= sigDigest sf
    then pure False
    else pqVerify pub digest (sigBytes sf)

saveSigFile :: FilePath -> SigFile -> IO ()
saveSigFile path sf = BSL.writeFile path (encode sf)

loadSigFile :: FilePath -> IO SigFile
loadSigFile path = decode <$> BSL.readFile path
