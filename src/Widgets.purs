module Widgets where

import Prelude
import Data.Number.Format (fixed, toStringWith)
import Halogen (ClassName(..))
import Halogen.HTML as HH
import Halogen.HTML.Events as HV
import Halogen.HTML.Properties (InputType(..), StepValue(..))
import Halogen.HTML.Properties as HE
import Module (Parameter(..))

slideWidget :: forall w i. String -> Number -> String -> Number -> Number -> Number -> (String -> i) -> HH.HTML w i
slideWidget name value unit min max step fn = HH.div [ HE.class_ $ ClassName "slide-widget" ] [ HH.span_ [ HH.text name ], slider, HH.span_ [ HH.text $ rounded <> unit ] ]
  where
  rounded = toStringWith (fixed 3) value

  slider = HH.input [ HE.type_ InputRange, HE.value (show value), HE.max max, HE.min min, HE.step $ Step step, HV.onValueInput fn ]

createWidget :: forall w i. Parameter -> (String -> i) -> HH.HTML w i
createWidget (Smooth name unit min max value) onChange = slideWidget name value unit min max 0.001 onChange
