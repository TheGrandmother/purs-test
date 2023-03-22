module Space where

import Prelude
import Data.List (List(..), fromFoldable, (:))
import Data.Number (abs, e, pow)
import Effect (Effect)
import Effect.Console (log)
import Effect.Random (random)
import El as El
import Materials (Material(..), absorbtionCoefficient, impedance, reflectionCoefficient, speedOfSound)

data Segment
  = Medium Material Number
  | Source El.Node
  | Mic

data World
  = Array Segment

testWorld1 :: List Segment
testWorld1 = fromFoldable [ Mic, Medium Air 10.0, Medium Wood 0.1, Medium Air 3.0, Medium Wood 0.1, Medium Air 10.0, Source El.quiet ]

traverse :: List Segment -> Effect El.Node
traverse l = _traverse Nil l
  where
  _traverse :: List Segment -> List Segment -> Effect El.Node
  _traverse Nil (Mic : ((Medium m dx) : ahead)) = do
    log "end case"
    rec <- _traverse ((Medium m dx) : Mic : Nil) ahead
    pure $ El.sdelay delay $ El.mul attenuation $ rec
    where
    delay = dx / (speedOfSound m)

    attenuation = attenuate dx (impedance m)

  _traverse ((Medium m0 _dx) : behind) ((Medium m1 dx) : ahead) = do
    n <- random
    log $ (show n) <> " > " <> (show (abs rc))
    if n > (abs rc) then do
      log "reflect"
      -- Going back trough self, m1 has no effect 
      rec <- _traverse ((Medium m1 dx) : ahead) ((Medium m0 _dx) : behind)
      pure $ El.mul 1.0 rec
    else do
      log "absorb"
      -- continue into material
      rec <- _traverse ((Medium m1 dx) : (Medium m0 _dx) : behind) ahead
      pure $ El.mul 1.0 rec
    where
    rc = (reflectionCoefficient m0 m1) * (pow e (-1.0 * (1.0 / dx)))

  -- ac = absorbtionCoefficient rc
  _traverse _ (Source n : Nil) = pure n

  _traverse (Source n : Nil) _ = pure n

  _traverse _ (Mic : Nil) = pure El.quiet

  _traverse (Mic : Nil) _ = pure El.quiet

  _traverse _ _ = pure El.quiet

attenuate :: Number -> Number -> Number
attenuate dx z = (pow e) $ -1.0 * dx * z * 0.0001

-- signal goes into a segment
--   compute natural frequency
--   Get absorbed and reflected parts
--   Pick probablility dependent on power
-- https://hal.science/hal-03188302/document
