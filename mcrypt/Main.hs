module Main (main) where

import Crypt.PQ.IO (getPQPrivate, getPQPublic, savePQKeys)
import Crypt.Sig (checkFile, loadSigFile, signFile)
import Options.Applicative
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

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
defaultKeyName = maybe "default" id

doSign :: FilePath -> Maybe String -> IO ()
doSign file key = do
  let name = defaultKeyName key
  priv <- getPQPrivate name
  sf <- signFile priv file
  let sigPath = file ++ ".sig"
  saveSigFile sigPath sf
  putStrLn $ "Signed " ++ file ++ " -> " ++ sigPath

doCheck :: FilePath -> Maybe String -> IO ()
doCheck file key = do
  let name = defaultKeyName key
  pub <- getPQPublic name
  sf <- loadSigFile (file ++ ".sig")
  ok <- checkFile pub file sf
  if ok
    then putStrLn "OK: signature valid"
    else do
      hPutStrLn stderr "FAIL: signature invalid or file modified"
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
