module Space where

import Prelude
import Data.List (List(..), fromFoldable, (:))
import Data.Maybe (Maybe(..))
import Data.Number (abs, e, pow, sign)
import Debug (trace)
import Effect (Effect)
import Effect.Console (log)
import Effect.Random (random)
import El (sample)
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
testWorld1 =
  fromFoldable
    [ Mic
    , Medium Air 10.0
    , Medium Wood 0.005
    , Medium Air 10.0
    , Medium Wood 0.01
    , Medium Air 40.0
    , Medium Wood 0.01
    , Medium Air 10.0
    --, Source (pulseGen 0.5 0.05 440.0)
    , Source (sample "test.wav" (pwmTrain 0.15 0.1) 1.0)
    ]

-- testWorld1 = fromFoldable [ Mic, Medium Air 10.0, Medium Wood 0.005, Medium Air 10.0, Source (pulseGen 0.5 0.05 330.0) ]
traverse :: List Segment -> Effect El.Node
traverse l = do
  ugh <- _traverse maxBounces Nil l
  case ugh of
    Just n -> do
      pure n
    Nothing -> do
      pure El.quiet
  where
  maxBounces = 50

  _traverse :: Int -> List Segment -> List Segment -> Effect (Maybe El.Node)
  _traverse x _ _
    | x == 0 = pure Nothing

  _traverse n Nil (Mic : ((Medium m dx) : ahead)) = do
    rec <- _traverse (n - 1) ((Medium m dx) : Mic : Nil) ahead
    pure $ Just ((transportNode m dx 1.0) $ rec)

  _traverse n ((Medium m0 _dx) : behind) ((Medium m1 dx) : ahead) = do
    pick <- random
    if pick < (abs rc) then do
      rec <- _traverse (n - 1) ((Medium m0 _dx) : (Medium m1 dx) : ahead) (behind)
      pure $ Just ((transportNode m0 _dx rc) $ rec)
    else do
      rec <- _traverse (n - 1) ((Medium m1 dx) : (Medium m0 _dx) : behind) ahead
      pure $ Just ((transportNode m1 dx rc) $ rec)
    where
    rc = (z1 - z0) / (z1 + z0)
      where
      z1 = impedance m1 * dx

      z0 = impedance m0 * _dx

  _traverse nn ((Medium m x) : _) (Source n : Nil) = do
    log ("found source after " <> (show (maxBounces - nn)))
    pure $ Just ((transportNode m x 1.0) (Just n))

  _traverse _ (Source n : Nil) _ = do
    pure (Just n)

  _traverse _ _ (Mic : Nil) = do
    pure Nothing

  _traverse _ (Mic : Nil) _ = do
    log "odd"
    pure Nothing

  _traverse _ _ _ = pure Nothing

transportNode :: Material -> Number -> Number -> (Maybe El.Node) -> El.Node
transportNode m x rc = \n -> case n of
  Just nn -> El.sdelay delay $ El.mul (attenuation * sign rc) $ El.lowpass fc 1.0 nn
  Nothing -> El.quiet
  where
  z = impedance m

  delay = x / (speedOfSound m)

  attenuation = attenuate x z

  fc = (20000.0 * (1.0 - ((pow e) $ (-1.0 / (x * z * z * 0.001)))))

attenuate :: Number -> Number -> Number
attenuate dx z = (pow e) $ -1.0 * dx * z * 0.001

-- ac = absorbtionCoefficient rc
-- signal goes into a segment
--   compute natural frequency
--   Get absorbed and reflected parts
--   Pick probablility dependent on power
-- https://hal.science/hal-03188302/document
