module Crypt.PQ.IO
  ( savePQKeys
  , getPQPublic
  , getPQPrivate
  ) where

import Crypt.PQ (PQPrivateKey (..), PQPublicKey (..))
import qualified Data.ByteString as BS
import System.Directory (createDirectoryIfMissing, getHomeDirectory)
import System.FilePath ((</>))

mcrypt :: String
mcrypt = ".mcrypt"

keyDir :: FilePath -> IO FilePath
keyDir name = do
  home <- getHomeDirectory
  let dir = home </> mcrypt </> name
  createDirectoryIfMissing True dir
  pure dir

savePQKeys :: PQPublicKey -> PQPrivateKey -> FilePath -> IO ()
savePQKeys (PQPublicKey pub) (PQPrivateKey priv) name = do
  dir <- keyDir name
  BS.writeFile (dir </> "public") pub
  BS.writeFile (dir </> "private") priv

getPQPublic :: FilePath -> IO PQPublicKey
getPQPublic name = do
  home <- getHomeDirectory
  PQPublicKey <$> BS.readFile (home </> mcrypt </> name </> "public")

getPQPrivate :: FilePath -> IO PQPrivateKey
getPQPrivate name = do
  home <- getHomeDirectory
  PQPrivateKey <$> BS.readFile (home </> mcrypt </> name </> "private")
