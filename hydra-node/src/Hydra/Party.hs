-- | Types and functions revolving around a Hydra 'Party'. That is, a
-- participant in a Hydra Head, which signs transactions or snapshots in the
-- Hydra protocol.
module Hydra.Party where

import Hydra.Prelude hiding (show)

import Data.Aeson (ToJSONKey)
import Data.Aeson.Types (FromJSONKey)
import Hydra.Cardano.Api (AsType (AsVerificationKey), SerialiseAsRawBytes (deserialiseFromRawBytes, serialiseToRawBytes), SigningKey, VerificationKey, getVerificationKey, verificationKeyHash)
import Hydra.Crypto (AsType (AsHydraKey), HydraKey)
import qualified Hydra.Data.Party as OnChain

-- | Identifies a party in a Hydra head by it's 'VerificationKey'.
newtype Party = Party {vkey :: VerificationKey HydraKey}
  deriving (Eq, Show, Generic)
  deriving anyclass (ToJSON, FromJSON, FromJSONKey, ToJSONKey)

-- REVIEW: Do we really want to define Ord or also use unordered-containers
-- based on Hashable?
instance Ord Party where
  Party{vkey = a} <= Party{vkey = b} =
    verificationKeyHash a <= verificationKeyHash b

instance Arbitrary Party where
  arbitrary = Party <$> arbitrary

instance FromCBOR Party where
  fromCBOR = Party <$> fromCBOR

instance ToCBOR Party where
  toCBOR Party{vkey} = toCBOR vkey

-- | Get the 'Party' given some Hydra 'SigningKey'.
deriveParty :: SigningKey HydraKey -> Party
deriveParty = Party . getVerificationKey

-- | Convert "high-level" 'Party' to the "low-level" representation as used
-- on-chain. See 'Hydra.Data.Party.Party' for an explanation why this is a
-- distinct type.
partyToChain :: Party -> OnChain.Party
partyToChain Party{vkey} =
  OnChain.partyFromVerificationKeyBytes $ serialiseToRawBytes vkey

-- | Retrieve the "high-level" 'Party from the "low-level" on-chain
-- representation. This can fail because of the lower type-safety used on-chain
-- and a non-guaranteed verification key length. See 'Hydra.Data.Party.Party'
-- for an explanation why this is a distinct type.
partyFromChain :: MonadFail m => OnChain.Party -> m Party
partyFromChain =
  maybe (fail "partyFromChain got Nothing") (pure . Party)
    . deserialiseFromRawBytes (AsVerificationKey AsHydraKey)
    . OnChain.partyToVerficationKeyBytes
