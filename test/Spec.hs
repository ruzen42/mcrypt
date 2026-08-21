import Crypt.PQ 

main :: IO ()
main = do
  (public, private) <- pqKeypair 
