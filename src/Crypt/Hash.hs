{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module Crypt.Hash (hashFile) where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteArray as BA
import qualified Data.ByteArray.Sized as BAS
import qualified BLAKE3

hashFile :: FilePath -> IO BS.ByteString
hashFile path = withBinaryFile path ReadMode $ \h -> do
  ctx <- BLAKE3.init @32 Nothing
  loop h ctx
  where
    chunkSize = 64 * 1024
    loop h ctx = do
      chunk <- BS.hGet h chunkSize
      if BS.null chunk
        then do
          let digest = BLAKE3.finalize ctx
              BLAKE3.Digest sizedBa = digest
          pure $ BA.convert (BAS.unSizedByteArray sizedBa)
        else do
          BLAKE3.update ctx chunk
          loop h ctx
