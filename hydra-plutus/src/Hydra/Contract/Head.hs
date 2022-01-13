{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# OPTIONS_GHC -fno-specialize #-}

module Hydra.Contract.Head where

import Ledger hiding (validatorHash)
import PlutusTx.Prelude

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)
import qualified Hydra.Contract.Commit as Commit
import Hydra.Contract.Encoding (serialiseTxOuts)
import Hydra.Data.ContestationPeriod (ContestationPeriod)
import Hydra.Data.Party (Party (UnsafeParty))
import Ledger.Typed.Scripts (TypedValidator, ValidatorTypes (RedeemerType))
import qualified Ledger.Typed.Scripts as Scripts
import Ledger.Typed.Scripts.Validators (DatumType)
import Plutus.Codec.CBOR.Encoding (
  encodeInteger,
  encodingToBuiltinByteString,
 )
import qualified PlutusTx
import Text.Show (Show)

type SnapshotNumber = Integer

type Hash = BuiltinByteString

data State
  = Initial {contestationPeriod :: ContestationPeriod, parties :: [Party]}
  | Open {parties :: [Party], utxoHash :: Hash}
  | Closed {snapshotNumber :: SnapshotNumber, utxoHash :: Hash}
  | Final
  deriving stock (Generic, Show)
  deriving anyclass (FromJSON, ToJSON)

PlutusTx.unstableMakeIsData ''State

data Input
  = CollectCom {utxoHash :: Hash}
  | Close
      { snapshotNumber :: SnapshotNumber
      , utxoHash :: Hash
      , signature :: [Signature]
      }
  | Abort
  | Fanout {numberOfFanoutOutputs :: Integer}
  deriving (Generic, Show)

PlutusTx.unstableMakeIsData ''Input

data Head

instance Scripts.ValidatorTypes Head where
  type DatumType Head = State
  type RedeemerType Head = Input

{-# INLINEABLE headValidator #-}
headValidator ::
  -- | Unique identifier for this particular Head
  -- TODO: currently unused
  MintingPolicyHash ->
  -- | Commit script address. NOTE: Used to identify inputs from commits and
  -- likely could be replaced by looking for PTs.
  Address ->
  State ->
  Input ->
  ScriptContext ->
  Bool
headValidator _ commitAddress oldState input context =
  case (oldState, input) of
    (Initial{}, CollectCom{}) ->
      -- TODO: check collected value is sent to own script output
      -- TODO: check collected txouts are put as datum in own script output
      let _collectedValue =
            foldr
              ( \TxInInfo{txInInfoResolved} val ->
                  if txOutAddress txInInfoResolved == commitAddress
                    then val + txOutValue txInInfoResolved
                    else val
              )
              mempty
              txInfoInputs
       in True
    (Initial{}, Abort) -> True
    (Open{parties}, Close{snapshotNumber, signature})
      | snapshotNumber == 0 -> True
      | snapshotNumber > 0 -> verifySnapshotSignature parties snapshotNumber signature
      | otherwise -> False
    (Closed{utxoHash}, Fanout{numberOfFanoutOutputs}) ->
      traceIfFalse "fannedOutUtxoHash /= closedUtxoHash" $ fannedOutUtxoHash numberOfFanoutOutputs == utxoHash
    _ -> False
 where
  fannedOutUtxoHash numberOfFanoutOutputs = hashTxOuts $ take numberOfFanoutOutputs txInfoOutputs

  TxInfo{txInfoInputs, txInfoOutputs} = txInfo

  ScriptContext{scriptContextTxInfo = txInfo} = context

hashTxOuts :: [TxOut] -> BuiltinByteString
hashTxOuts =
  sha2_256 . serialiseTxOuts
{-# INLINEABLE hashTxOuts #-}

{-# INLINEABLE verifySnapshotSignature #-}
verifySnapshotSignature :: [Party] -> SnapshotNumber -> [Signature] -> Bool
verifySnapshotSignature parties snapshotNumber sigs =
  traceIfFalse "signature verification failed" $
    length parties == length sigs
      && all (uncurry $ verifyPartySignature snapshotNumber) (zip parties sigs)

{-# INLINEABLE verifyPartySignature #-}
verifyPartySignature :: SnapshotNumber -> Party -> Signature -> Bool
verifyPartySignature snapshotNumber vkey signed =
  traceIfFalse "party signature verification failed" $
    mockVerifySignature vkey snapshotNumber (getSignature signed)

{-# INLINEABLE mockVerifySignature #-}
-- TODO: This really should be the builtin Plutus function 'verifySignature' but as we
-- are using Mock crypto in the Head, so must we use Mock crypto on-chain to verify
-- signatures.
mockVerifySignature :: Party -> SnapshotNumber -> BuiltinByteString -> Bool
mockVerifySignature (UnsafeParty vkey) snapshotNumber signed =
  traceIfFalse "mock signed message is not equal to signed" $
    mockSign vkey (encodingToBuiltinByteString $ encodeInteger snapshotNumber) == signed

{-# INLINEABLE mockSign #-}
mockSign :: Integer -> BuiltinByteString -> BuiltinByteString
mockSign vkey msg = appendByteString (sliceByteString 0 8 hashedMsg) (encodingToBuiltinByteString $ encodeInteger vkey)
 where
  hashedMsg = sha2_256 msg

-- | The script instance of the auction state machine. It contains the state
-- machine compiled to a Plutus core validator script. The 'MintingPolicyHash' serves
-- two roles here:
--
--   1. Parameterizing the script, such that we get a unique address and allow
--   for multiple instances of it
--
--   2. Identify the 'state thread token', which should be passed in
--   transactions transitioning the state machine and provide "contract
--   continuity"
--
-- TODO: Add a NetworkId so that we can properly serialise address hashes
-- see 'encodeAddress' for details
typedValidator :: MintingPolicyHash -> TypedValidator Head
typedValidator policyId =
  Scripts.mkTypedValidator @Head
    compiledValidator
    $$(PlutusTx.compile [||wrap||])
 where
  compiledValidator =
    $$(PlutusTx.compile [||headValidator||])
      `PlutusTx.applyCode` PlutusTx.liftCode policyId
      `PlutusTx.applyCode` PlutusTx.liftCode Commit.address

  wrap = Scripts.wrapValidator @(DatumType Head) @(RedeemerType Head)

validatorHash :: MintingPolicyHash -> ValidatorHash
validatorHash = Scripts.validatorHash . typedValidator

address :: MintingPolicyHash -> Address
address = scriptHashAddress . validatorHash

-- | Get the actual plutus script. Mainly used to serialize and use in
-- transactions.
validatorScript :: MintingPolicyHash -> Script
validatorScript = unValidatorScript . Scripts.validatorScript . typedValidator
