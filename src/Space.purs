module Space where

import Prelude

import Data.List (List(..), fromFoldable, (:))
import Data.Number (e, pow)
import El as El
import Materials (Material(..), impedance, speedOfSound)

data Segment
  = Medium Material Number
  | Source
  | Mic

data World = Array Segment

testWorld1 :: List Segment
testWorld1 = fromFoldable [Medium Air 10.0, Medium Concrete 1.0, Medium Air 3.0]

traverse :: List Segment -> List Segment -> El.Node
traverse Nil ((Medium m dx) : ahead) = El.sdelay (dx / (speedOfSound m)) $ El.mul (attenuate dx $ impedance m ) $ traverse ((Medium m dx) : Nil) ahead
traverse _ _ = El.quiet


attenuate :: Number -> Number -> Number
attenuate dx z = (pow e) $ -1.0 * dx * z * 0.0001

-- signal goes into a segment
--   compute natural frequency
--   Get absorbed and reflected parts
--   Pick probablility dependent on power

-- https://hal.science/hal-03188302/document
