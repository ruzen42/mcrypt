module Main (main) where

import Crypt.IO (getPrivate, getPublic, keyExist)
import Crypt.Sig (checkFile, loadSigFile, signFile, saveSigFile)
import Options.Applicative
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)
import Control.Monad (unless)

data Command
  = Sign String (Maybe String)
  | Check String (Maybe String)

main :: IO ()
main = do
  act <- execParser optsInfo
  case act of
    Sign file key -> doSign file key
    Check file key -> doCheck file key

defaultKeyName :: Maybe String -> String
defaultKeyName = maybe "main" id

doSign :: FilePath -> Maybe String -> IO ()
doSign file key = do
  let name = defaultKeyName key
  raw <- getPrivate name
  case raw of
    Right priv -> do
      sf   <- signFile priv file
      let sigPath = file ++ ".mcrypt"
      saveSigFile sigPath sf
      putStrLn $ "signed " ++ file ++ " -> " ++ sigPath
    Left err ->
      hPutStrLn stderr $ "error: please create " ++ name ++ " key before using it: " ++ err
      exitFailure

doCheck :: FilePath -> Maybe String -> IO ()
doCheck file key = do
  let name = defaultKeyName key

  raw <- getPublic name
  case raw of 
    Right pub -> do
      sf  <- loadSigFile (file ++ ".mcrypt")
      ok  <- checkFile pub file sf
      if ok
        then putStrLn "good: signature valid"
        else do
          hPutStrLn stderr "bad: signature invalid or file modified"
          exitFailure
    Left err -> do
      hPutStrLn stderr $ "error: please create " ++ name ++ " key before using it: " ++ err
      exitFailure
      

optsInfo :: ParserInfo Command
optsInfo =
  info
    (commandParser <**> helper)
    ( fullDesc
        <> progDesc "sign and verify files with BLAKE3 + Dilithium3 (post-quantum)"
    )

keyOpt :: Parser (Maybe String)
keyOpt =
  optional $
    strOption
      ( long "key"
          <> short 'k'
          <> metavar "KEY"
          <> help "name of the keyset to use (default: \"default\")"
      )

commandParser :: Parser Command
commandParser = signParser <|> checkParser

signParser :: Parser Command
signParser =
  Sign
    <$> strOption
      ( long "sign"
          <> short 's'
          <> metavar "FILE"
          <> help "sign your file"
      )
    <*> keyOpt

checkParser :: Parser Command
checkParser =
  Check
    <$> strOption
      ( long "check"
          <> short 'C'
          <> metavar "FILE"
          <> help "check signature"
      )
    <*> keyOpt
