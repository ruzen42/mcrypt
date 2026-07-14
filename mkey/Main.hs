module Main (main) where

import Crypt.Gen (newIOKeys)
import Options.Applicative 
import Crypt.IO (saveKeys, getAll, getPrivate, getPublic)

data Command
    = New String
    | Get String
    | List
    | Delete String

main :: IO ()
main = do
    action <- execParser optsInfo

    case action of
        New name -> do
            (pub, prv) <- newIOKeys
            saveKeys pub prv name

            putStrLn $ "Created key \"" ++ name ++ "\""

        Get name -> do
            mpub <- getPublic name
            mprv <- getPrivate name

            case (mpub, mprv) of
                (Just pub, Just prv) -> do
                    putStrLn "Public:"
                    print pub
                    putStrLn "Private:"
                    print prv

                _ ->
                    putStrLn "Key not found."

        List -> do
            keys <- getAll
            mapM_ putStrLn keys

        Delete name -> do
            putStrLn "Not implemented."



optsInfo :: ParserInfo Command
optsInfo =
    info
        (commandParser <**> helper)
        ( fullDesc
       <> progDesc "Simple cryptokeys generator"
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
