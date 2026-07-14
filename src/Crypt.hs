module Crypt (PublicKey, PrivateKey, powMod) where

type PublicKey  = (Integer, Integer)
type PrivateKey = (Integer, Integer)

powMod :: Integer -> Integer -> Integer
powMod _ 0 = 1
powMod a n 
  | even n = binPow (a * a) (n `div` 2)
  | otherwise = a * binPow (a * a) ((n - 1) `div` 2) 


