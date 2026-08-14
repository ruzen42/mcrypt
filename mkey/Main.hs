module Main (main) where

import Options.Applicative 
import Crypt.PQ.IO (savePQKeys, getPQPublic, getAllKeys, keyExist)
import Crypt.IO (removeKeys)
import Crypt.PQ (pqKeypair)

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
            (pub, prv) <- pqKeypair 
            savePQKeys pub prv name

            putStrLn $ "created key \"" ++ name ++ "\""

        Get name -> do
            exist <- keyExist name 
            mpub <- getPQPublic name

            case exist of
                True -> print mpub
                _    -> putStrLn "key not found... :("

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

