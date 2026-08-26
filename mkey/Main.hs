module Main (main) where

import Options.Applicative 
import Crypt.IO (save, getPublic, getAllKeys, keyExist, removeKeys)
import Crypt (newKeypair, printKey)

data Command
    = New String
    | Get String
    | List
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
            mpub <- getPublic name

            case mpub of
                Right pub  -> printKey $ pub 
                Left err   -> putStrLn err 

        List -> do
            keys <- getAllKeys
            mapM_ putStrLn keys

        Delete name -> removeKeys name 

optsInfo :: ParserInfo Command
optsInfo =
    info
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

