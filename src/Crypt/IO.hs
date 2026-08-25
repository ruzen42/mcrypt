{-# LANGUAGE OverloadedStrings #-}
module Crypt.IO
  ( save
  , getPublic 
  , getPrivate
  , getAllKeys
  , keyExist
  , removeKeys
  ) where

import Crypt (PrivateKey (..), PublicKey (..))
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Base64 as B64
import System.Directory
  ( createDirectoryIfMissing
  , listDirectory
  , doesDirectoryExist
  , removeDirectoryRecursive, getAppUserDataDirectory
  )
import System.FilePath ((</>))

getMCryptBaseDir :: IO FilePath
getMCryptBaseDir = getAppUserDataDirectory "mcrypt"

getKeyDir :: FilePath -> IO FilePath
getKeyDir name = do
  base <- getMCryptBaseDir
  pure $ base </> name

getMCryptDir :: FilePath -> IO FilePath
getMCryptDir name = do
  dir <- getKeyDir name
  createDirectoryIfMissing True dir
  pure dir

getAllKeys :: IO [FilePath]
getAllKeys = do 
  dir <- getMCryptBaseDir 
  exist <- doesDirectoryExist dir
  if exist 
    then listDirectory dir 
    else pure []

keyExist :: FilePath -> IO Bool
keyExist name = do
  dir <- getKeyDir name
  doesDirectoryExist dir

save :: PublicKey -> PrivateKey -> FilePath -> IO ()
save pub priv name = do
  dir <- getMCryptDir name
  savePublic pub "example@mcrypt.com" dir
  savePrivate priv dir

savePublic :: PublicKey -> ByteString -> FilePath -> IO ()
savePublic (PublicKey pub) userData dir = do
  let key = B64.encode pub
  BS.writeFile (dir </> "public") ("mcrypt-dilithium3-1.1.0 " <> key <> " " <> userData)

savePrivate :: PrivateKey -> FilePath -> IO ()
savePrivate (PrivateKey prv) dir = do
  let key  = B64.encode prv
      file = "-----BEGIN MCRYPT PRIVATE KEY-----\n" <> key <> "\n-----END MCRYPT PRIVATE KEY-----"
  BS.writeFile (dir </> "private") file

getPublic :: FilePath -> IO (Either String PublicKey)
getPublic name = do
  dir <- getKeyDir name
  exist <- doesDirectoryExist dir
  if not exist
    then pure $ Left "key directory does not exist"
    else do
      raw <- BS.readFile (dir </> "public")
      pure $ PublicKey <$> parsePublic raw 
  where 
    parsePublic :: ByteString -> Either String ByteString
    parsePublic raw = case BC.words raw of
      (_ : dat : _) -> B64.decode dat
      [dat]         -> B64.decode dat
      _             -> Left "public key is invalid" 

getPrivate :: FilePath -> IO (Either String PrivateKey)
getPrivate name = do
  dir <- getKeyDir name
  exist <- doesDirectoryExist dir
  if not exist
    then pure $ Left "key directory does not exist"
    else do
      raw <- BS.readFile (dir </> "private")
      pure $ PrivateKey <$> parsePrivate raw 
  where 
    parsePrivate :: ByteString -> Either String ByteString
    parsePrivate raw = 
      let ls = BC.lines raw
          content = BS.concat $ filter (\l -> not (BC.isPrefixOf "---" l)) ls
      in B64.decode content

removeKeys :: FilePath -> IO ()
removeKeys name = do 
  dir <- getKeyDir name
  exist <- doesDirectoryExist dir
  if exist
    then removeDirectoryRecursive dir
    else pure ()
