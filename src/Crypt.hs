{-# LANGUAGE DeriveGeneric #-}
module Crypt (PublicKey(..), 
  PrivateKey(..), IOKey(..), 
  powMod, programVer, public2IO, 
  private2IO, io2private, io2public) where

import GHC.Generics (Generic)
import Data.Binary (Binary) 

programVer :: Int 
programVer = 2

data PublicKey  = PublicKey 
  { publicE :: Integer
  , publicN :: Integer
  } 

instance Show PublicKey where
  show key = show (publicE key) ++ " " ++ show (publicN key)

data PrivateKey = PrivateKey 
  { privateD :: Integer
  , privateN :: Integer
  } 

instance Show PrivateKey where
  show key = show (privateD key) ++ " " ++ show (privateN key)



data IOKey = IOKey 
  { version :: Int 
  , kType   :: Bool 
  , value1  :: Integer
  , value2  :: Integer
  } deriving (Show, Generic)

instance Binary IOKey

private2IO :: PrivateKey -> IOKey
private2IO pk = IOKey
  { version = programVer
  , kType   = True  -- means private 
  , value1  = privateD pk
  , value2  = privateN pk
  }

public2IO :: PublicKey -> IOKey
public2IO pk = IOKey
  { version = programVer
  , kType   = False -- means public   
  , value1  = publicE pk
  , value2  = publicN pk
  }

powMod :: Integer -> Integer -> Integer -> Integer
powMod base exp modulus = go 1 (base `mod` modulus) exp
  where
    go acc _ 0 = acc
    go acc b e
        | odd e     = go ((acc * b) `mod` modulus)
                         ((b * b) `mod` modulus)
                         (e `div` 2)
        | otherwise = go acc
                         ((b * b) `mod` modulus)
                         (e `div` 2)

io2public :: IOKey -> Maybe PublicKey
io2public io = 
  if not (kType io)
    then Just $ PublicKey (value1 io) (value2 io)
    else Nothing

io2private :: IOKey -> Maybe PrivateKey
io2private io = 
  if kType io
    then Just $ PrivateKey (value1 io) (value2 io)
    else Nothing
