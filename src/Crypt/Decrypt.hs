module Crypt.Decrypt (decrypt) where

import Crypt 

decrypt :: PrivateKey -> Integer -> Integer 
decrypt (d,n) cipher = powMod cipher d n
