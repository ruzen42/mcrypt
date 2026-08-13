module Crypt.IO (saveKeys, savePublic, savePrivate, getPrivate, getPublic, getAll, removeKeys) where

import Crypt
import qualified Data.ByteString.Lazy as BSL  -- Fixed: need Lazy ByteString for encode/decode
import Data.Binary (encode, decode)
import System.Directory (createDirectoryIfMissing, getHomeDirectory, listDirectory, removeDirectoryRecursive)
import System.FilePath ((</>))

mcrypt :: String 
mcrypt = ".mcrypt" 

saveKeys :: PublicKey -> PrivateKey -> FilePath -> IO ()
saveKeys pub prv name = do 
  savePublic pub name 
  savePrivate prv name 

savePublic :: PublicKey -> FilePath -> IO ()
savePublic key name = do 
  dir <- createDir name 
  let io = public2IO key  
  BSL.writeFile (dir </> "public") (encode io) 
 
savePrivate :: PrivateKey -> FilePath -> IO ()
savePrivate key name = do 
  dir <- createDir name 
  let io = private2IO key  
  BSL.writeFile (dir </> "private") (encode io) 

getPublic :: FilePath -> IO (Maybe PublicKey)
getPublic name = do 
  home <- getHomeDirectory
  let dir = home </> mcrypt </> name
  file <- BSL.readFile (dir </> "public")
  let ioKey = decode file
  return $ io2public ioKey

getPrivate :: FilePath -> IO (Maybe PrivateKey)
getPrivate name = do 
  home <- getHomeDirectory
  let dir = home </> mcrypt </> name
  file <- BSL.readFile (dir </> "private")
  let ioKey = decode file
  return $ io2private ioKey


createDir :: FilePath -> IO FilePath 
createDir name = do 
  home <- getHomeDirectory
  let dir = home </> mcrypt </> name
  createDirectoryIfMissing True dir 
  return dir

getAll :: IO [FilePath]
getAll = do
  home <- getHomeDirectory
  let dir = home </> mcrypt 
  createDirectoryIfMissing True dir  
  files <- listDirectory dir
  return $ map (dir </>) files

removeKeys :: FilePath -> IO ()
removeKeys key = do 
  home <- getHomeDirectory
  let dir = home </> mcrypt </> key
  removeDirectoryRecursive dir
