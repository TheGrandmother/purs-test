module Space where

import Prelude

import Data.List (List(..), fromFoldable, (:))
import Data.Maybe (Maybe(..))
import Data.Number (abs, e, pow)
import Effect (Effect)
import Effect.Console (log)
import Effect.Random (random)
import El as El
import Materials (Material(..), impedance, speedOfSound)

data Segment
  = Medium Material Number
  | Source El.Node
  | Mic


instance showMaterial :: Show Segment where
  show (Medium mat d) = (show mat) <> (show d)
  show (Source _) = "source"
  show Mic = "Mic"

data World
  = Array Segment


tc :: String -> Number -> El.Node
tc t v = El.const t v

pwmTrain :: Number -> Number -> El.Node
pwmTrain freq duty = El.sm $ El.le (El.ramp $ tc "f" freq) $ tc "d" duty

pulseGen :: Number -> Number -> Number -> El.Node
pulseGen pulseFreq duty freq = El.mul (El.cycle $ El.const "os_f" freq) (pwmTrain pulseFreq duty)


testWorld1 :: List Segment
testWorld1 = fromFoldable [
  Mic,
  Medium Air 10.0,
  Medium Wood 0.005,
  Medium Air 50.0,
  Medium Wood 0.01,
  Medium Air 20.0,
  Medium Wood 0.005,
  Medium Air 10.0,
  Source (pulseGen 0.5 0.05 440.0)
]
-- testWorld1 = fromFoldable [ Mic, Medium Air 10.0, Medium Wood 0.005, Medium Air 10.0, Source (pulseGen 0.5 0.05 330.0) ]

traverse :: List Segment -> Effect El.Node
traverse l = do
  ugh <- _traverse 500 Nil l
  case ugh of
    Just n -> pure n
    Nothing -> pure El.quiet
  where
  _traverse :: Int -> List Segment -> List Segment -> Effect (Maybe El.Node)
  _traverse x _ _ | x == 0 = pure Nothing

  _traverse n Nil (Mic : ((Medium m dx) : ahead)) = do
    rec <- _traverse (n-1) ((Medium m dx) : Mic : Nil) ahead
    pure $ Just ((transportNode m dx) $ rec)

  _traverse n ((Medium m0 _dx) : behind) ((Medium m1 dx) : ahead) = do
    pick <- random
    log $ (show (Medium m0 _dx)) <> " | " <> (show (Medium m1 dx))
    -- log $ (show pick) <> " > " <> (show (abs rc))
    if pick < (abs rc) then do
      log "reflecting"
      rec <- _traverse (n - 1) ((Medium m0 _dx) : (Medium m1 dx) : ahead) (behind)
      pure $ Just((transportNode m0 _dx) $ rec)
    else do
      log "absorbing"
      rec <- _traverse (n - 1) ((Medium m1 dx) : (Medium m0 _dx) : behind) ahead
      pure $ Just((transportNode m1 dx) $ rec)
    where
    rc = (z1 - z0) / (z1 + z0)
      where
        z1 = impedance m1 * dx
        z0 = impedance m0 * _dx

  _traverse _ ((Medium m x) : _) (Source n : Nil) = do
     log "Arrived at source"
     pure $ Just((transportNode m x) (Just n))

  _traverse _ (Source n : Nil) _ = pure (Just n)

  _traverse _ _ (Mic : Nil) = do
     log "Returned to mic"
     pure Nothing

  _traverse _ (Mic : Nil) _ = pure Nothing

  _traverse _ _ _ = pure Nothing

transportNode :: Material -> Number -> (Maybe El.Node) -> El.Node
transportNode m x = \n -> case n of
    Just nn -> El.sdelay delay $ El.mul attenuation $ nn
    Nothing -> El.quiet
  where
    delay = x / (speedOfSound m)
    attenuation = attenuate x (impedance m)

attenuate :: Number -> Number -> Number
attenuate dx z = (pow e) $ -1.0 * dx * z * 0.01
-- ac = absorbtionCoefficient rc

-- signal goes into a segment
--   compute natural frequency
--   Get absorbed and reflected parts
--   Pick probablility dependent on power
-- https://hal.science/hal-03188302/document
