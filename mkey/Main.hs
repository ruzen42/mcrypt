module Main (main) where

import Crypt.Gen (newIOKeys)
import Options.Applicative 
import Crypt.IO (saveKeys, getAll, getPublic, removeKeys)

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
            (pub, prv) <- newIOKeys
            saveKeys pub prv name

            putStrLn $ "created key \"" ++ name ++ "\""

        Get name -> do
            mpub <- getPublic name

            case mpub of
                Just pub -> do
                    print pub
                _ ->
                    putStrLn "key not found... :("

        List -> do
            keys <- getAll
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
       <> metavar "NAME"
       <> help "Generate a new key pair"
        )

getParser :: Parser Command
getParser =
    Get <$> strOption
        ( long "get"
       <> metavar "NAME"
       <> help "Load a key"
        )

listParser :: Parser Command
listParser =
    flag' List
        ( long "list"
       <> help "List keys"
        )

deleteParser :: Parser Command
deleteParser =
    Delete <$> strOption
        ( long "delete"
       <> metavar "NAME"
       <> help "Delete a key"
        )
