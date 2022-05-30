module Hydra.Data.ContestationPeriodSpec where

import Hydra.Prelude

import Hydra.Data.ContestationPeriod (
  contestationPeriodFromDiffTime,
  contestationPeriodToDiffTime,
  posixToUTCTime,
 )
import Plutus.Orphans ()
import Test.Hspec (Spec, describe)
import Test.Hspec.QuickCheck (prop)
import Test.QuickCheck (collect, (===))

spec :: Spec
spec = do
  describe "to/from NominalDiffTime" $
    prop "is isomorphic to NominalDiffTime" $ \t ->
      let diff = contestationPeriodToDiffTime t
       in contestationPeriodFromDiffTime diff === t

  describe "posixToUTCTime" $ do
    prop "is homomorphic w.r.t to Ord" $ \t1 t2 ->
      let ordering = compare t1 t2
       in ordering === compare (posixToUTCTime t1) (posixToUTCTime t2)
            & collect ordering