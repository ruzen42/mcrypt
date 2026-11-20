-- SPDX-License-Identifier: MIT

{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import Driver (Algorithm (..), algorithmName, newKeypair)
import MCrypt.IO (getAllKeys, getPublicRaw, removeKeys, save)
import Data.Version (showVersion)
import Options.Applicative
import Paths_mcrypt (version)
import qualified Data.Text as T

data Command
  = New String Algorithm
  | Get String
  | Delete String
  | List (Maybe Algorithm)
  | Version Bool

main :: IO ()
main = do
  commandAction <- execParser optsInfo
  case commandAction of
    New name algorithm -> do
      pair <- newKeypair algorithm
      save pair name
      putStrLn $ "created " ++ algorithmName algorithm ++ " key \"" ++ name ++ "\""
    Get name -> do
      result <- getPublicRaw name
      either putStrLn putStrLn result
    List requested -> do
      names <- getAllKeys
      records <- mapM (\name -> do
        raw <- getPublicRaw name
        let alg = either (const "") (takeAlgorithm) raw
        pure (alg, name)) names
      let selected = filter (matches requested) records
      mapM_ (putStrLn . snd) (sortOn fst selected)
    Delete name -> removeKeys name
    Version detailed ->
      if detailed
        then do
          putStrLn $ "mkey " ++ showVersion version
          putStrLn "component: mkey"
          putStrLn "supported algorithms: ml-dsa-65"
        else putStrLn $ showVersion version

optsInfo :: ParserInfo Command
optsInfo = info (commandParser <**> helper)
  (fullDesc <> progDesc "mcrypt project key management tool")

commandParser :: Parser Command
commandParser = hsubparser
  ( command "new" (info newCmd (progDesc "Generate a new key"))
 <> command "get" (info getCmd (progDesc "Get a public key"))
 <> command "delete" (info deleteCmd (progDesc "Delete a key folder"))
 <> command "list" (info listCmd (progDesc "List available keys"))
 <> command "version" (info versionCmd (progDesc "Print version"))
  )

newCmd :: Parser Command
newCmd = New
  <$> argument str (metavar "NAME" <> value "master" <> showDefault <> help "Key name")
  <*> option (eitherReader parseAlgorithm)
      (   short 'a' <> metavar "ALGORITHM" <> value MlDsa65
       <> showDefaultWith algorithmName <> help "Algorithm (ml-dsa-65)")

parseAlgorithm :: String -> Either String Algorithm
parseAlgorithm "ml-dsa-65" = Right MlDsa65
parseAlgorithm other = Left $ "unsupported algorithm: " ++ other ++ " (supported: ml-dsa-65)"

listCmd :: Parser Command
listCmd = List <$> optional (option (eitherReader parseAlgorithm)
  (short 'a' <> metavar "ALGORITHM"
   <> help "Filter and sort keys by algorithm (ml-dsa-65)"))

versionCmd :: Parser Command
versionCmd = Version <$> switch
  (short 'a' <> help "Show component and supported protocol details")

takeAlgorithm :: String -> Text
takeAlgorithm raw = case T.words (toText raw) of
  (label : _) -> T.drop (T.length "mcrypt-") label
  _ -> ""

matches :: Maybe Algorithm -> (Text, String) -> Bool
matches Nothing _ = True
matches (Just algorithm) (name, _) = name == toText (algorithmName algorithm)

getCmd :: Parser Command
getCmd = Get <$> argument str (metavar "NAME" <> help "Key name")

deleteCmd :: Parser Command
deleteCmd = Delete <$> argument str (metavar "NAME" <> help "Key name to delete")
