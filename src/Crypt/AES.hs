{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Crypt.AES
  ( Key
  , createAESKey
  , keyFromBytes
  , keyBytes
  , encryptFile
  , decryptFile
  ) where

import Crypto.Cipher.AES (AES256)
import Crypto.Cipher.Types (BlockCipher(..), Cipher(..), IV, makeIV)
import Crypto.Random (getRandomBytes)
import Crypto.Error (CryptoFailable(..))
import Control.Concurrent.Async (mapConcurrently_)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import Data.Bits (shiftR)
import Data.Word (Word64)
import System.IO
  ( IOMode(..), withBinaryFile, hSeek, SeekMode(..)
  , hFileSize, hSetFileSize
  )

newtype Key = Key ByteString
  deriving (Eq, Show)

createAESKey :: IO Key
createAESKey = Key <$> getRandomBytes 32

keyBytes :: Key -> ByteString
keyBytes (Key bs) = bs

keyFromBytes :: ByteString -> Either String Key
keyFromBytes bs
  | BS.length bs == 32 = Right (Key bs)
  | otherwise = Left "AES-256 key must be 32 bytes"

chunkSize :: Word64
chunkSize = 64 * 1024 * 1024 -- 64 MiB

addCounter :: ByteString -> Word64 -> IV AES256
addCounter nonceBS blocks =
  let (prefix, counterBS) = BS.splitAt 8 nonceBS
      counterVal = bsToWord64BE counterBS
      newCounter = word64ToBSBE (counterVal + blocks)
      newNonce = prefix `BS.append` newCounter
  in case makeIV newNonce :: Maybe (IV AES256) of
       Just iv -> iv
       Nothing -> error "internal error: bad nonce length"

bsToWord64BE :: ByteString -> Word64
bsToWord64BE = BS.foldl' (\acc w -> (acc `shiftL'` 8) + fromIntegral w) 0
  where shiftL' x n = x * (2 ^ n)

word64ToBSBE :: Word64 -> ByteString
word64ToBSBE w = BS.pack [ fromIntegral (w `shiftR` (i * 8)) | i <- [7,6..0] ]

initCipher :: Key -> AES256
initCipher (Key keyBS) = case cipherInit keyBS of
  CryptoFailed err -> error $ "failed to init cipher: " ++ show err
  CryptoPassed c    -> c

-- File: [16 bytes nonce]
encryptFile :: Key -> FilePath -> FilePath -> IO ()
encryptFile key srcPath dstPath = do
  let cipher = initCipher key
  nonceBS <- getRandomBytes 16
  withBinaryFile srcPath ReadMode $ \hIn -> do
    totalSize <- fromIntegral <$> hFileSize hIn
    withBinaryFile dstPath WriteMode $ \hOut ->
      hSetFileSize hOut (fromIntegral (16 + totalSize) :: Integer)
    BS.writeFile dstPath nonceBS  
    let offsets = takeWhileNonEmpty [0, chunkSize .. ] totalSize
    mapConcurrently_ (processChunk cipher nonceBS srcPath dstPath) offsets
  where
    takeWhileNonEmpty offs total = takeWhile (< total) offs

    processChunk cipher nonceBS src dst offset =
      withBinaryFile src ReadMode $ \hIn ->
        withBinaryFile dst ReadWriteMode $ \hOut -> do
          hSeek hIn AbsoluteSeek (fromIntegral offset)
          chunkData <- BS.hGet hIn (fromIntegral chunkSize)
          let blocksOffset = offset `div` 16
              chunkIv = addCounter nonceBS blocksOffset
              out = ctrCombine cipher chunkIv chunkData
          hSeek hOut AbsoluteSeek (fromIntegral (16 + offset))
          BS.hPut hOut out

-- CTR is symmetric
decryptFile :: Key -> FilePath -> FilePath -> IO ()
decryptFile key srcPath dstPath = do
  let cipher = initCipher key
  nonceBS <- withBinaryFile srcPath ReadMode $ \hIn -> BS.hGet hIn 16
  withBinaryFile srcPath ReadMode $ \hIn -> do
    fullSize <- fromIntegral <$> hFileSize hIn
    let totalSize = fullSize - 16
    withBinaryFile dstPath WriteMode $ \hOut ->
      hSetFileSize hOut (fromIntegral totalSize :: Integer)
    let offsets = takeWhile (< totalSize) [0, chunkSize ..]
    mapConcurrently_ (processChunk cipher nonceBS srcPath dstPath) offsets
  where
    processChunk cipher nonceBS src dst offset =
      withBinaryFile src ReadMode $ \hIn ->
        withBinaryFile dst ReadWriteMode $ \hOut -> do
          hSeek hIn AbsoluteSeek (fromIntegral (16 + offset))
          chunkData <- BS.hGet hIn (fromIntegral chunkSize)
          let blocksOffset = offset `div` 16
              chunkIv = addCounter nonceBS blocksOffset
              out = ctrCombine cipher chunkIv chunkData
          hSeek hOut AbsoluteSeek (fromIntegral offset)
          BS.hPut hOut out
