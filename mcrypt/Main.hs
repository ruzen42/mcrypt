module Main (main) where

import Crypt.Gen (newIOKeys)
import Options.Applicative 
import Crypt.IO (saveKeys, getAll, getPublic, removeKeys)

data Command
    = Crypt String (Maybe String)
    | Decrypt String (Maybe String)
    | Sign String (Maybe String)
    | Check String (Maybe String)

main :: IO ()
main = do
    act <- execParser optsInfo

    case act of
        Crypt file key   -> error "not implemented"
        Decrypt file key -> error "not implemented"
        Sign file key    -> error "not implemented"
        Check file key   -> error "not implemented"

optsInfo :: ParserInfo Command
optsInfo =
    info
        (commandParser <**> helper)
        ( fullDesc
       <> progDesc "crypt and sign your files"
        )

keyOpt :: Parser (Maybe String)
keyOpt = optional $ strOption
    ( long "key"
   <> short 'k'
   <> metavar "KEY"
   <> help "Optional encryption key" )

commandParser :: Parser Command
commandParser = 
       cryptParser
    <|> decryptParser
    <|> signParser
    <|> checkParser

cryptParser :: Parser Command
cryptParser =
    Crypt <$> strOption
        ( long "crypt"
       <> short 'c'
       <> metavar "FILE"
       <> help "crypt your file"
        )
    <*> keyOpt

decryptParser :: Parser Command
decryptParser =
    Decrypt <$> strOption
        ( long "decrypt"
       <> short 'd'
       <> metavar "FILE"
       <> help "decrypt your file"
        )
    <*> keyOpt

signParser :: Parser Command
signParser =
    Sign <$> strOption
        ( long "sign"
       <> short 's'
       <> metavar "FILE"
       <> help "sign your file"
        )
    <*> keyOpt

checkParser :: Parser Command
checkParser =
    Check <$> strOption
        ( long "check"
       <> short 'C'  
       <> metavar "FILE"
       <> help "check signature"
        )
    <*> keyOpt

