module Crypt.Decrypt (decrypt) where

import Crypt 

decrypt :: PrivateKey -> Integer -> Integer 
decrypt (PrivateKey d n) cipher = powMod cipher d n
