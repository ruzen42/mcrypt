-- SPDX-License-Identifier: MIT
{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import MCrypt.IO (getPrivate, getPublic)
import MCrypt.Sig (sign, verify, loadSigFile, encryptFile, decryptFile)
import qualified MCrypt.AES as AES
import Options.Applicative
import System.IO (hPutStrLn)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Base64 as B64
import Data.Version (showVersion)
import Paths_mcrypt (version)

data Command
  = Sign    FilePath (Maybe String)
  | Check   FilePath (Maybe String)
  | Encrypt FilePath (Maybe String)
  | Decrypt FilePath (Maybe String)
  | Version Bool

main :: IO ()
main = do
  act <- execParser optsInfo
  case act of
    Sign file key    -> doSign file key
    Check file key   -> doCheck file key
    Encrypt file key -> doEncrypt file key
    Decrypt file key -> doDecrypt file key
    Version detailed ->
      if detailed
        then do
          putStrLn $ "mcrypt " ++ showVersion version
          putStrLn "component: mcrypt (file signing and encryption CLI)"
          putStrLn "supported algorithms: ml-dsa-65"
          putStrLn "protocols: ML-DSA-65 : signatures, BLAKE3 : digests, AES-256-CTR : encryption"
        else putStrLn $ showVersion version

defaultKeyName :: Maybe String -> String
defaultKeyName = maybe "master" id

doSign :: FilePath -> Maybe String -> IO ()
doSign file key = do
  let name = defaultKeyName key
  raw <- getPrivate name
  case raw of
    Right priv -> do
      _ <- sign priv file
      putStrLn $ "signed " ++ file ++ " -> " ++ file ++ ".asc"
    Left err -> do
      hPutStrLn stderr $ "error: please create " ++ name ++ " key before using it: " ++ err
      exitFailure

doCheck :: FilePath -> Maybe String -> IO ()
doCheck file key = do
  let name = defaultKeyName key
  raw <- getPublic name
  case raw of
    Right pub -> do
      sfResult <- loadSigOrExit file
      ok <- verify pub file sfResult
      if ok
        then putStrLn "good: signature valid"
        else do
          hPutStrLn stderr "bad: signature invalid or file modified"
          exitFailure
    Left err -> do
      hPutStrLn stderr $ "error: please create " ++ name ++ " key before using it `mkey new " ++ name ++ "`\t" ++ err
      exitFailure
  where
    loadSigOrExit f = do
      r <- loadSigFile (f ++ ".asc")
      case r of
        Right sf -> pure sf
        Left err -> do
          hPutStrLn stderr $ "error: " ++ err
          exitFailure

doEncrypt :: FilePath -> Maybe String -> IO ()
doEncrypt file key = do
  let name = defaultKeyName key
  raw <- getPrivate name
  case raw of
    Right priv -> do
      aesKey <- AES.createAESKey
      let dstPath = file ++ ".enc"
          keyPath = file ++ ".enc.key"
      _ <- encryptFile priv aesKey file dstPath
      BS.writeFile keyPath (B64.encode (AES.keyBytes aesKey))
      putStrLn $ "encrypted " ++ file ++ " -> " ++ dstPath
      putStrLn $ "key saved -> " ++ keyPath
      putStrLn "WARNING: keep the .key file secret and separate from the .enc file"
    Left err -> do
      hPutStrLn stderr $ "error: please create " ++ name ++ " key before using it `mkey new " ++ name ++ "`\t" ++ err
      exitFailure

doDecrypt :: FilePath -> Maybe String -> IO ()
doDecrypt file key = do
  let name = defaultKeyName key
  raw <- getPublic name
  case raw of
    Right pub -> do
      let keyPath = file ++ ".enc.key"
      keyRaw <- BS.readFile keyPath
      case B64.decode keyRaw >>= AES.keyFromBytes of
        Left err -> do
          hPutStrLn stderr $ "error: bad key file " ++ keyPath ++ ": " ++ err
          exitFailure
        Right aesKey -> do
          let dstPath = stripEncSuffix file ++ ".new"
          result <- decryptFile pub aesKey file dstPath
          case result of
            Left err -> do
              hPutStrLn stderr $ "error: " ++ err
              exitFailure
            Right () -> putStrLn $ "decrypted " ++ file ++ " -> " ++ dstPath
    Left err -> do
      hPutStrLn stderr $ "error: please create " ++ name ++ " key before using it `mkey new " ++ name ++ "`\t" ++ err
      exitFailure
  where
    stripEncSuffix f =
      let suffix = ".enc"
      in if suffix `isSuffixOfStr` f
           then take (length f - length suffix) f
           else f
    isSuffixOfStr suf s = suf == drop (length s - length suf) s

optsInfo :: ParserInfo Command
optsInfo =
  info
    (commandParser <**> helper)
    ( fullDesc
        <> progDesc "main utility from MCrypt project (post-quantum file )"
    )

keyOpt :: Parser (Maybe String)
keyOpt =
  optional $
    strOption
      ( short 'k'
      <> metavar "NAME"
      <> value "master" 
      <> help "name of the keypair to use" 
      )

commandParser :: Parser Command
commandParser = hsubparser
  ( command "sign" (info signParser (progDesc "Sign a file"))
 <> command "check" (info checkParser (progDesc "Verify a file signature"))
 <> command "encrypt" (info encryptParser (progDesc "Encrypt a file"))
 <> command "decrypt" (info decryptParser (progDesc "Decrypt a file"))
 <> command "version" (info versionParser (progDesc "Print version"))
  )

signParser :: Parser Command
signParser =
  Sign
    <$> argument str (metavar "FILE" <> help "File to sign")
    <*> keyOpt

checkParser :: Parser Command
checkParser =
  Check
    <$> argument str (metavar "FILE" <> help "File to verify")
    <*> keyOpt

versionParser :: Parser Command
versionParser = Version <$> switch
  (short 'a' <> help "Show component and supported protocol details")

encryptParser :: Parser Command
encryptParser =
  Encrypt
    <$> argument str (metavar "FILE" <> help "File to encrypt")
    <*> keyOpt

decryptParser :: Parser Command
decryptParser =
  Decrypt
    <$> argument str (metavar "FILE" <> help "File to decrypt")
    <*> keyOpt
