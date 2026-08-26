module Main (main) where

import Options.Applicative 
import Crypt.IO (save, getPublicRaw, getKeyDir, getAllKeys, removeKeys)
import Crypt (newKeypair)
import Data.Version (showVersion)
import Paths_mcrypt_tools (version)

data Command
    = New String
    | Get String
    | List
    | Version
    | Delete String

main :: IO ()
main = do
    act <- execParser optsInfo
    case act of
        New name -> do
            (pub, prv) <- newKeypair 
            save pub prv name
            putStrLn $ "created key \"" ++ name ++ "\""
        Get name -> do
            pub <- getPublicRaw name
            case pub of
              Right key -> putStrLn key
              Left err  -> putStrLn err
        List -> do
            raw  <- getAllKeys
            keys <- mapM getKeyDir raw
            mapM_ putStrLn keys

        Delete name -> removeKeys name 
        Version     -> 
          putStrLn $ showVersion version

optsInfo :: ParserInfo Command
optsInfo = info
        (commandParser <**> helper)
        ( fullDesc
       <> progDesc "simple cryptokeys generator"
        )

commandParser :: Parser Command
commandParser =
        newParser
    <|> getParser
    <|> listParser
    <|> deleteParser
    <|> versionParser

versionParser :: Parser Command
versionParser = flag' Version
  ( long "version"
 <> short 'v'
 <> help "print version in major.minor.patch tags format"
  )

newParser :: Parser Command
newParser =
    New <$> strOption
        ( long "new"
       <> short 'n' 
       <> metavar "NAME"
       <> help "generate a new key pair"
        )

getParser :: Parser Command
getParser =
    Get <$> strOption
        ( long "get"
       <> metavar "NAME"
       <> short 'g' 
       <> help "get public key"
        )

listParser :: Parser Command
listParser =
    flag' List
        ( long "list"
       <> short 'l' 
       <> help "list keys"
        )

deleteParser :: Parser Command
deleteParser =
    Delete <$> strOption
        ( long "delete"
       <> metavar "NAME"
       <> short 'd' 
       <> help "Delete a key"
        )

