module Crypt.Encrypt (encrypt) where

import Crypt 

encrypt :: PublicKey -> Integer -> Integer 
encrypt (e,n) msg = 
  powMod msg e n
