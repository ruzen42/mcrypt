{-# LANGUAGE ForeignFunctionInterface #-}

module Crypt
  ( PublicKey (..)
  , PrivateKey (..)
  , PQAlgError (..)
  , algName
  , publicKeyLength
  , secretKeyLength
  , newKeypair
  , sign
  , verify
  ) where
 
import Control.Exception (Exception, throwIO)
import Control.Monad (when)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Unsafe as BSU
import Foreign
import Foreign.C.Types
 
-- name of the fixed signature algorithm (informational  for inclusion in signature file headers)
algName :: String
algName = "OQS_SIG_alg_ml_dsa_65"

newtype PublicKey = PublicKey { unPublic :: BS.ByteString }
  deriving (Eq, Show)
 
newtype PrivateKey = PQPrivateKey { unPrivate :: BS.ByteString }
  deriving (Eq, Show)
 
newtype AlgError = AlgError String

instance Show AlgError where
  show (AlgError s) = "AlgError: " ++ s

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
    throwIO $ PQAlgError $
      "liboqs was not built with " ++ algName
        ++ " support (rebuild liboqs with -DOQS_ENABLE_SIG_dilithium_3=ON)"
 
-- generate a neww Dilithium3 keypair
newKeypair :: IO (PublicKey, PrivateKey)
newKeypair = do
  pubLen <- publicKeyLength
  secLen <- secretKeyLength
  requireAlg pubLen
  requireAlg secLen
  allocaBytes pubLen $ \pubPtr ->
    allocaBytes secLen $ \secPtr -> do
      rc <- c_keypair pubPtr secPtr
      when (rc /= 0) $ throwIO (PQAlgError "OQS_SIG_keypair failed")
      pub <- BS.packCStringLen (castPtr pubPtr, pubLen)
      sec <- BS.packCStringLen (castPtr secPtr, secLen)
      pure (PublicKey pub, PrivateKey sec)
 
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
          when (secLen' <= 0) $ throwIO (PQAlgError "empty secret key")
          when (rc /= 0) $ throwIO (PQAlgError "OQS_SIG_sign failed")
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
