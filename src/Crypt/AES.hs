{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Crypt.AESParallel
  ( Key
  , createAESKey
  , processFileCTRParallel
  ) where

import Crypto.Cipher.AES (AES256)
import Crypto.Cipher.Types (BlockCipher(..), Cipher(..), IV, makeIV)
import Crypto.Random (getRandomBytes)
import Control.Concurrent.Async (mapConcurrently_)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import System.IO
  ( FilePath, IOMode(..), withBinaryFile, hSeek, SeekMode(..)
  , hGet, hPut, hFileSize, Handle
  )
import Data.Word (Word64)
import Foreign.Marshal.Alloc (allocaBytes)
import Foreign.Ptr (castPtr)
import Foreign.Storable (poke, peek)

newtype Key = Key ByteString
  deriving (Eq, Show)

createAESKey :: IO Key
createAESKey = Key <$> getRandomBytes 32

chunkSize :: Word64
chunkSize = 64 * 1024 * 1024 -- 64MiB

addIV :: IV AES256 -> Word64 -> IV AES256
addIV iv blocks =
  let ivBS = BS.copy $ cipherIVuntag iv
      (headIV, tailIV) = BS.splitAt 8 ivBS
  in case makeIVBytes (incTail tailIV blocks) of
       Just newIv -> newIv
       Nothing    -> error "failed to increment IV"
  where
    incTail bs add =
      let val = bsToWord64 bs
          newVal = val + add
      in headIV `BS.append` word64ToBS newVal

    makeIVBytes b = makeIV b :: Maybe (IV AES256)

    bsToWord64 bs = unsafePerformIO $ BS.useAsCString bs $ \ptr -> do
      w <- peek (castPtr ptr :: Ptr Word64)
      return (byteSwap64 w)

    word64ToBS w = BS.pack $ map (\i -> fromIntegral (w `shiftR` (i * 8))) [7,6..0]

processFileCTRParallel :: Key -> FilePath -> FilePath -> IO ()
processFileCTRParallel (Key keyBS) srcPath dstPath =
  case cipherInit keyBS :: CryptoFailable AES256 of
    CryptoFailed err -> error $ "failed to init cipher: " ++ show err
    CryptoPassed cipher -> do
      rawIv <- getRandomBytes 16
      case makeIV rawIv :: Maybe (IV AES256) of
        Nothing -> error "Invalid IV"
        Just initialIv -> do
          BS.writeFile dstPath rawIv
          
          withBinaryFile srcPath ReadMode $ \hIn -> do
            totalSize <- fromIntegral <$> hFileSize hIn
            let numChunks = (totalSize + chunkSize - 1) `div` chunkSize
                offsets = [0, chunkSize .. totalSize - 1]

            mapConcurrently_ (processChunk cipher initialIv) offsets
  where
    processChunk cipher baseIv offset =
      withBinaryFile srcPath ReadMode $ \hIn ->
        withBinaryFile dstPath ReadWriteMode $ \hOut -> do
          let blocksOffset = offset `div` 16
              chunkIv = addIV baseIv blocksOffset
          
          hSeek hIn AbsoluteSeek (fromIntegral offset)
          hSeek hOut AbsoluteSeek (fromIntegral $ offset + 16) 
          
          chunkData <- BS.hGet hIn (fromIntegral chunkSize)
          let processedData = ctrCombine cipher chunkIv chunkData
          
          BS.hPut hOut processedData
