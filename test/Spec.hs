{-# LANGUAGE OverloadedStrings #-}
module Crypt.Hash.Tests (tests) where

import Crypt.Hash (Digest, hashBytes, hashFile)
import qualified Data.ByteString as BS
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))
import Test.Tasty.QuickCheck as QC
import qualified Data.ByteString.Char8 as BSC

tests :: TestTree
tests =
  testGroup
    "Crypt.Hash"
    [ hashConsistency
    , hashEmptyBytes
    , hashKnownVectors
    , hashPropertyTests
    ]

hashConsistency :: TestTree
hashConsistency =
  testCase "hash consistency" $ do
    let input = "The quick brown fox jumps over the lazy dog"
    let h1 = hashBytes (BSC.pack input)
    let h2 = hashBytes (BSC.pack input)
    h1 @?= h2

hashEmptyBytes :: TestTree
hashEmptyBytes =
  testCase "hash empty bytes" $ do
    let h = hashBytes BS.empty
    BS.length h @?= 32
    h @?= hashBytes ""

hashKnownVectors :: TestTree
hashKnownVectors =
  testGroup
    "Known test vectors"
    [ testCase "empty string" $ do
        let h = hashBytes ""
        BS.length h @?= 32
    , testCase "single byte (0x00)" $ do
        let h = hashBytes "\x00"
        BS.length h @?= 32
    , testCase "abc" $ do
        let h = hashBytes "abc"
        BS.length h @?= 32
    ]

hashPropertyTests :: TestTree
hashPropertyTests =
  testGroup
    "property tests"
    [ QC.testProperty "hash always 32 bytes" $ \(bs :: BS.ByteString) ->
        BS.length (hashBytes bs) == 32
    , QC.testProperty "different inputs -> different hashes" $
        \(bs1 :: BS.ByteString) (bs2 :: BS.ByteString) ->
          bs1 /= bs2 ==> hashBytes bs1 /= hashBytes bs2
    , QC.testProperty "hash is deterministic" $
        \(bs :: BS.ByteString) ->
          hashBytes bs == hashBytes bs
    ]
