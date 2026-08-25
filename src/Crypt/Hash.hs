{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module Crypt.Hash (hashFile) where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteArray as BA
import qualified Data.ByteArray.Sized as BAS
import qualified BLAKE3

hashFile :: FilePath -> IO BS.ByteString
hashFile path = do
  contents <- BL.readFile path
  pure $! hashBytesLazy contents

hashBytesLazy :: BL.ByteString -> BS.ByteString
hashBytesLazy lbs =
    let chunks = BL.toChunks lbs  
        digest = BLAKE3.hash @32 Nothing chunks :: BLAKE3.Digest 32
        BLAKE3.Digest sizedBa = digest
        rawArray = BAS.unSizedByteArray sizedBa
    in BA.convert rawArray
