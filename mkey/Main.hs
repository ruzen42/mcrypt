module Main (main) where

import Crypt.Gen (newIOKeys)

main :: IO ()
main = do
  (pub, prv) <- newIOKeys 
  
  putStr "Public "
  print pub

  putStr "Private "

  print prv
