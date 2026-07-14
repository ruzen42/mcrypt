module Crypt.IO (saveKeys, savePublic, savePrivate, getPrivate, getPublic, getAll) where

import Crypt
import qualified Data.ByteString.Lazy as BSL  -- Исправлено: нужен Lazy ByteString для encode/decode
import Data.Binary (encode, decode)
import System.Directory (createDirectoryIfMissing, getHomeDirectory, listDirectory)
import System.FilePath ((</>))

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
  let dir = home </> ".mcrypt" </> name
  file <- BSL.readFile (dir </> "public")
  let ioKey = decode file
  return $ io2public ioKey

getPrivate :: FilePath -> IO (Maybe PrivateKey)
getPrivate name = do 
  home <- getHomeDirectory
  let dir = home </> ".mcrypt" </> name
  file <- BSL.readFile (dir </> "private")
  let ioKey = decode file
  return $ io2private ioKey


createDir :: FilePath -> IO FilePath 
createDir name = do 
  home <- getHomeDirectory
  let dir = home </> ".mcrypt" </> name
  createDirectoryIfMissing True dir 
  return dir

getAll :: IO [FilePath]
getAll = do
  home <- getHomeDirectory
  let dir = home </> ".mcrypt"
  createDirectoryIfMissing True dir  
  files <- listDirectory dir
  return $ map (dir </>) files
  
