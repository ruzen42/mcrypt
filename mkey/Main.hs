-- SPDX-License-Identifier: MIT
module Main (main) where

import Driver (Algorithm (..), algorithmName, newKeypair)
import MCrypt.IO (getAllKeys, getKeyDir, getPublicRaw, removeKeys, save)
import Data.Version (showVersion)
import Options.Applicative
import Paths_mcrypt_tools (version)

data Command
  = New String Algorithm
  | Get String
  | Delete String
  | List
  | Version

main :: IO ()
main = do
  action <- execParser optsInfo
  case action of
    New name algorithm -> do
      pair <- newKeypair algorithm
      save pair name
      putStrLn $ "created " ++ algorithmName algorithm ++ " key \"" ++ name ++ "\""
    Get name -> do
      result <- getPublicRaw name
      either putStrLn putStrLn result
    List -> getAllKeys >>= mapM getKeyDir >>= mapM_ putStrLn
    Delete name -> removeKeys name
    Version -> putStrLn $ showVersion version

optsInfo :: ParserInfo Command
optsInfo = info (commandParser <**> helper)
  (fullDesc <> progDesc "mcrypt project key management tool")

commandParser :: Parser Command
commandParser = hsubparser
  ( command "new" (info newCmd (progDesc "Generate a new key"))
 <> command "get" (info getCmd (progDesc "Get a public key"))
 <> command "delete" (info deleteCmd (progDesc "Delete a key folder"))
 <> command "list" (info (pure List) (progDesc "List available keys"))
 <> command "version" (info (pure Version) (progDesc "Print version"))
  )

newCmd :: Parser Command
newCmd = New
  <$> argument str (metavar "NAME" <> value "master" <> showDefault <> help "Key name")
  <*> option (eitherReader parseAlgorithm)
      (long "algorithm" <> short 'a' <> metavar "ALGORITHM" <> value MlDsa65
       <> showDefaultWith algorithmName <> help "Algorithm (ml-dsa-65)")

parseAlgorithm :: String -> Either String Algorithm
parseAlgorithm "ml-dsa-65" = Right MlDsa65
parseAlgorithm other = Left $ "unsupported algorithm: " ++ other ++ " (supported: ml-dsa-65)"

getCmd :: Parser Command
getCmd = Get <$> argument str (metavar "NAME" <> help "Key name")

deleteCmd :: Parser Command
deleteCmd = Delete <$> argument str (metavar "NAME" <> help "Key name to delete")
