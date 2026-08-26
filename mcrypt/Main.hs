module Main (main) where

import Crypt.IO (getPrivate, getPublic, keyExist)
import Crypt.Sig (sign, verify, loadSigFile, encryptFile, decryptFile)
import qualified Crypt.AES as AES
import Options.Applicative
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Base64 as B64

data Command
  = Sign    String (Maybe String)
  | Check   String (Maybe String)
  | Encrypt String (Maybe String)
  | Decrypt String (Maybe String)

main :: IO ()
main = do
  act <- execParser optsInfo
  case act of
    Sign file key    -> doSign file key
    Check file key   -> doCheck file key
    Encrypt file key -> doEncrypt file key
    Decrypt file key -> doDecrypt file key

defaultKeyName :: Maybe String -> String
defaultKeyName = maybe "main" id

doSign :: FilePath -> Maybe String -> IO ()
doSign file key = do
  let name = defaultKeyName key
  raw <- getPrivate name
  case raw of
    Right priv -> do
      _ <- sign priv file
      putStrLn $ "signed " ++ file ++ " -> " ++ file ++ ".mcrypt"
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
      hPutStrLn stderr $ "error: please create " ++ name ++ " key before using it: " ++ err
      exitFailure
  where
    loadSigOrExit f = do
      r <- loadSigFile (f ++ ".mcrypt")
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
      hPutStrLn stderr $ "error: please create " ++ name ++ " key before using it: " ++ err
      exitFailure

-- | Расшифровывает file (ожидается путь к .enc), ключ читается из
-- file-без-суффикса-.enc ++ ".key", либо из file ++ ".key" если суффикса нет.
doDecrypt :: FilePath -> Maybe String -> IO ()
doDecrypt file key = do
  let name = defaultKeyName key
  raw <- getPublic name
  case raw of
    Right pub -> do
      let keyPath = file ++ ".key"
      keyRaw <- BS.readFile keyPath
      case B64.decode keyRaw >>= AES.keyFromBytes of
        Left err -> do
          hPutStrLn stderr $ "error: bad key file " ++ keyPath ++ ": " ++ err
          exitFailure
        Right aesKey -> do
          let dstPath = stripEncSuffix file ++ ".dec"
          result <- decryptFile pub aesKey file dstPath
          case result of
            Left err -> do
              hPutStrLn stderr $ "error: " ++ err
              exitFailure
            Right () -> putStrLn $ "decrypted " ++ file ++ " -> " ++ dstPath
    Left err -> do
      hPutStrLn stderr $ "error: please create " ++ name ++ " key before using it: " ++ err
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
        <> progDesc "sign, verify, encrypt and decrypt files (post-quantum)"
    )

keyOpt :: Parser (Maybe String)
keyOpt =
  optional $
    strOption
      ( long "key"
          <> short 'k'
          <> metavar "KEY"
          <> help "name of the keyset to use (default: \"main\")"
      )

commandParser :: Parser Command
commandParser = signParser <|> checkParser <|> encryptParser <|> decryptParser

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

encryptParser :: Parser Command
encryptParser =
  Encrypt
    <$> strOption
      ( long "encrypt"
          <> short 'e'
          <> metavar "FILE"
          <> help "encrypt file"
      )
    <*> keyOpt

decryptParser :: Parser Command
decryptParser =
  Decrypt
    <$> strOption
      ( long "decrypt"
          <> short 'd'
          <> metavar "FILE"
          <> help "decrypt file"
      )
    <*> keyOpt
