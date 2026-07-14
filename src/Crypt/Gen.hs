module Crypt.Gen (newIOKeys, newKeys, generateKeys) where

import Crypt
import System.Random 

-- in future, add polymorchic RandomGen instead of StdGen

randomInteger :: StdGen -> Integer -> Integer -> (Integer, StdGen)
randomInteger gen low high = 
  let 
    (x, gen') = random gen :: (Integer, StdGen)
    range = high - low + 1
    n = low + (abs x `mod` range)
  in 
    (n, gen')

generatePrime :: StdGen -> Integer -> Integer -> (Integer, StdGen)
generatePrime gen low high = 
  let 
    (n0, gen') = randomInteger gen low high 
    n = if even n0 then n0 + 1 else n0
      in 
    if isPrime n
      then (n, gen')
      else generatePrime gen' low high
  where 
    isPrime n 
      | n == 2     = True
      | n <= 1     = False
      | even n     = False
      | otherwise  = not (any (\x -> n `mod` x == 0) [3, 5..limit])
      where 
        limit = floor $ sqrt $ fromIntegral n


generateThreePrimes
    :: StdGen
    -> Integer
    -> Integer
    -> ((Integer, Integer, Integer), StdGen)
generateThreePrimes gen low high =
    let
        (p, g1) = generatePrime gen low high
        (q, g2) = generatePrime g1 low high
        (r, g3) = generatePrime g2 low high
    in
        ((p, q, r), g3)

newIOKeys :: IO (PublicKey, PrivateKey)
newIOKeys = do
  gen <- newStdGen 
  pure $ newKeys gen

newKeys :: StdGen -> (PublicKey, PrivateKey)
newKeys gen = 
  let 
    low = 0
    high = 92992019203922
    ((p, q, _), _) = generateThreePrimes gen low high
  in 
    generateKeys p q 65537

generateKeys :: Integer -> Integer -> Integer -> (PublicKey, PrivateKey)
generateKeys p q e = 
  let 
    n = p * q
    phi = (p - 1) * (q - 1)
    d = modInverse e phi
  in 
    (PublicKey{publicE=e,publicN=n},PrivateKey{privateD=d,privateN=n})
  where
    egcd :: Integer -> Integer -> (Integer, Integer, Integer)
    egcd a 0 = (a, 1, 0)
    egcd a b =
      let
        (g, x, y) = egcd b (a `mod` b)
      in
        (g, y, x - (a `div` b) * y)
    modInverse :: Integer -> Integer -> Integer
    modInverse a m =
      let
        (g, x, _) = egcd a m
      in
        if g /= 1
            then error "Inverse does not exist"
            else x `mod` m
