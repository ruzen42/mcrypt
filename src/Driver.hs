-- SPDX-License-Identifier: MIT

{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE OverloadedStrings        #-}

module Driver
  ( PublicKey (..)
  , PrivateKey (..)
  , Algorithm (..)
  , KeyPair (..)
  , AlgError (..)
  , algName
  , publicKeyLength
  , secretKeyLength
  , newKeypair
  , algorithmName
  , sign
  , verify
  , printKey
  ) where
 
import Control.Exception (throwIO)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Unsafe as BSU
import Foreign
import Foreign.C.Types
import Prelude hiding (All)
 
-- name of the fixed signature algorithm (informational  for inclusion in signature file headers)
algName :: String
algName = "OQS_SIG_alg_ml_dsa_65"

data Algorithm = MlDsa65
  deriving (Eq, Show, Read, Enum, Bounded)

algorithmName :: Algorithm -> String
algorithmName MlDsa65 = "ml-dsa-65"

data KeyPair = KeyPair
  { keyAlgorithm :: Algorithm
  , keyPublic :: PublicKey
  , keyPrivate :: PrivateKey
  } deriving (Eq, Show)

printKey :: PublicKey -> IO ()
printKey key = BS.putStr $ (unPublic key) <> "\n"

newtype PublicKey = PublicKey { unPublic :: BS.ByteString }
  deriving (Eq, Show)
 
newtype PrivateKey = PrivateKey { unPrivate :: BS.ByteString }
  deriving (Eq, Show)
 
newtype AlgError = AlgError String
  deriving (Show)

instance Exception AlgError
 
foreign import ccall unsafe "mcrypt_sig_public_key_len"
  c_pub_len :: IO CSize
 
foreign import ccall unsafe "mcrypt_sig_secret_key_len"
  c_sec_len :: IO CSize
 
foreign import ccall unsafe "mcrypt_sig_max_signature_len"
  c_max_sig_len :: IO CSize
 
foreign import ccall unsafe "mcrypt_sig_keypair"
  c_keypair :: Ptr Word8 -> Ptr Word8 -> IO CInt
 
foreign import ccall unsafe "mcrypt_sig_sign"
  c_sign
    :: Ptr Word8 -> Ptr CSize
    -> Ptr Word8 -> CSize
    -> Ptr Word8
    -> IO CInt
 
foreign import ccall unsafe "mcrypt_sig_verify"
  c_verify
    :: Ptr Word8 -> CSize
    -> Ptr Word8 -> CSize
    -> Ptr Word8
    -> IO CInt

-- wrappers for C functions
publicKeyLength :: IO Int
publicKeyLength = fromIntegral <$> c_pub_len
 
secretKeyLength :: IO Int
secretKeyLength = fromIntegral <$> c_sec_len
 
signatureMaxLength :: IO Int
signatureMaxLength = fromIntegral <$> c_max_sig_len
 
requireAlg :: Int -> IO ()
requireAlg n =
  when (n == 0) $
    throwIO $ AlgError $
      "liboqs was not built with " ++ algName
        ++ " support (rebuild liboqs with -DOQS_ENABLE_SIG_dilithium_3=ON)"
 
-- generate a neww Dilithium3 keypair
newKeypair :: Algorithm -> IO KeyPair
newKeypair algorithm = do
  pubLen <- publicKeyLength
  secLen <- secretKeyLength
  requireAlg pubLen
  requireAlg secLen
  allocaBytes pubLen $ \pubPtr ->
    allocaBytes secLen $ \secPtr -> do
      rc <- c_keypair pubPtr secPtr
      when (rc /= 0) $ throwIO (AlgError "OQS_SIG_keypair failed")
      pub <- BS.packCStringLen (castPtr pubPtr, pubLen)
      sec <- BS.packCStringLen (castPtr secPtr, secLen)
      pure KeyPair
        { keyAlgorithm = algorithm
        , keyPublic = PublicKey pub
        , keyPrivate = PrivateKey sec
        }
 
-- sign a message (in practice: a BLAKE3 digest, please see 'Crypt.Hash' modull) with a D3 private key
sign :: PrivateKey -> BS.ByteString -> IO BS.ByteString
sign (PrivateKey sec) msg = do
  maxSigLen <- signatureMaxLength
  requireAlg maxSigLen
  BSU.unsafeUseAsCStringLen msg $ \(msgPtr, msgLen) ->
    BSU.unsafeUseAsCStringLen sec $ \(secPtr, secLen') ->
      allocaBytes maxSigLen $ \sigPtr ->
        alloca $ \sigLenPtr -> do
          poke sigLenPtr (fromIntegral maxSigLen)
          rc <-
            c_sign
              (castPtr sigPtr) sigLenPtr
              (castPtr msgPtr) (fromIntegral msgLen)
              (castPtr secPtr)
          when (secLen' <= 0) $ throwIO (AlgError "empty secret key")
          when (rc /= 0) $ throwIO (AlgError "OQS_SIG_sign failed")
          actualLen <- peek sigLenPtr
          BS.packCStringLen (castPtr sigPtr, fromIntegral actualLen)
 
-- verify a D3 signature never throws on a bad signature
-- returns False only throws on genuine misuse (algorithm unavailable)
verify :: PublicKey -> BS.ByteString -> BS.ByteString -> IO Bool
verify (PublicKey pub) msg sig = do
  pubLen <- publicKeyLength
  requireAlg pubLen
  BSU.unsafeUseAsCStringLen msg $ \(msgPtr, msgLen) ->
    BSU.unsafeUseAsCStringLen sig $ \(sigPtr, sigLen) ->
      BSU.unsafeUseAsCStringLen pub $ \(pubPtr, _) -> do
        rc <-
          c_verify
            (castPtr msgPtr) (fromIntegral msgLen)
            (castPtr sigPtr) (fromIntegral sigLen)
            (castPtr pubPtr)
        pure (rc == 0)
