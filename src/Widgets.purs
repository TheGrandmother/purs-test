module Widgets
  ( createSmoothSlider
  , createIntSlider
  ) where

import Prelude

import Data.Int (floor, toNumber)
import Data.Maybe (Maybe(..))
import Data.Number (fromString)
import Data.Number.Format (fixed, toStringWith)
import Halogen.HTML as HH
import Halogen.HTML.Events as HV
import Halogen.HTML.Properties as HE

slideWidget :: forall w i. String -> Number -> String -> Number -> Number -> Number -> (String -> i) -> HH.HTML w i
slideWidget name value unit min max step fn = HH.div_ [ HH.span_ [ HH.text name ], slider, HH.span_ [ HH.text $ rounded <> unit ] ]
  where
  rounded = toStringWith (fixed 2) value

  slider = HH.input [ HE.type_ HE.InputRange, HE.value (show value), HE.max max, HE.min min, HE.step $ HE.Step step, HV.onValueInput fn ]

createSmoothSlider :: forall w i. String -> String -> Number -> Number -> Number -> (Number -> i) -> HH.HTML w i
createSmoothSlider name unit min max value onChange = slideWidget name value unit min max 0.001 change
  where
  change = \s -> onChange $ case fromString s of
    Just n -> n
    Nothing -> 0.0

createIntSlider :: forall w i. String -> Int -> Int -> Int -> (Int -> i) -> HH.HTML w i
createIntSlider name min max value onChange = slideWidget name (toNumber value) "" (toNumber min) (toNumber max) 1.0 change
  where
  change = \s -> onChange $ case fromString s of
    Just n -> floor n
    Nothing -> 0
