module Crypt.PQ.IO
  ( savePQKeys
  , getPQPublic
  , getPQPrivate
  , getAllKeys
  , keyExist
  ) where

import Crypt.PQ (PQPrivateKey (..), PQPublicKey (..))
import qualified Data.ByteString as BS
import System.Directory (createDirectoryIfMissing, getHomeDirectory, listDirectory, doesDirectoryExist)
import System.FilePath ((</>))

mcrypt :: String
mcrypt = ".mcrypt"

keyDir :: FilePath -> IO FilePath
keyDir name = do
  home <- getHomeDirectory
  let dir = home </> mcrypt </> name
  createDirectoryIfMissing True dir
  pure dir

getAllKeys :: IO [FilePath]
getAllKeys = do 
  home <- getHomeDirectory
  let dir = home </> mcrypt 
  listDirectory dir 

keyExist :: FilePath -> IO Bool
keyExist name = do
  dir <- keyDir name
  doesDirectoryExist dir

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
