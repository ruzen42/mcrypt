module Crypt.AES () where

import Crypto.Cipher.AES
import Crypto.Random
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS 
import Crypto.Cipher.Types (makeIv)

encryptData :: AES256 -> ByteString -> ByteString -> ByteString -> ByteString
encryptData cipher key iv dataToEncrypt =
  let block = 16 
      paddedData = padBS block dataToEncrypt
  in cbcEncrypt cipher key iv paddedData

padBS :: Int -> ByteString -> ByteString
padBS bs bs' = bs' `BS.append` BS.replicate (bs - (bs' `BS.length` `mod` bs)) (fromIntegral (bs - (bs' `BS.length` `mod` bs)))

generateAES256Key :: IO ByteString
generateAES256Key = getRandomBytes 32 

generateAES256Iv :: IO ByteString
generateAES256Iv = getRandomBytes 16 
