module Widgets(moduleWidget, createWidget) where

import Prelude

import Data.Number (fromString)
import Data.Number.Format (fixed, toStringWith)
import Data.Tuple (Tuple(..))
import Halogen (ClassName(..))
import Halogen.HTML as HH
import Halogen.HTML.Events as HV
import Halogen.HTML.Properties (IProp, InputType(..), StepValue(..))
import Halogen.HTML.Properties as HE
import Module (Parameter(..))
import Module as M

slideWidget :: forall w i. String -> Number -> String -> Number -> Number -> Number -> (String -> i) -> HH.HTML w i
slideWidget name value unit min max step fn = HH.div [ HE.class_ $ ClassName "slide-widget" ] [ HH.span_ [ HH.text name ], slider, HH.span_ [ HH.text $ rounded <> unit ] ]
  where
  rounded = toStringWith (fixed 2) value

  slider = HH.input [ HE.type_ InputRange, HE.value (show value), HE.max max, HE.min min, HE.step $ Step step, HV.onValueInput fn ]

createWidget :: forall w i. M.Parameter -> (String -> i) -> HH.HTML w i
createWidget (Smooth name unit min max value) onChange = slideWidget name value unit min max 0.001 onChange

moduleWidget :: forall w179 i180. (M.Parameter -> i180) -> M.RackModule -> HH.HTML w179 i180
moduleWidget onChange m = HH.div [ cn "rack-module" ] [ namePlate, spacer, inputPlate, HH.div [cn "control-plate"] controls , outputPlate]
  where 
    spacer = HH.div [ cn "spacer" ] []
    controls = makeControl <$> (M.getControls m)
    makeControl (Tuple name param) = createWidget param (\e -> onChange (updater param e) )
    updater p e = M.setValue p (fromString e)
    {namePlate, inputPlate, outputPlate} = moduleBase $ M.moduleInfo m

moduleBase :: forall w i.
  M.ModuleInfo -> { inputPlate :: HH.HTML w i, namePlate :: HH.HTML w i, outputPlate :: HH.HTML w i}
moduleBase { name, id, inputs, outputs } = { namePlate, inputPlate, outputPlate }
  where
  namePlate = HH.div [ cn "head-plate" ] [ HH.span [ cn "module-name" ] [ HH.text name ], HH.span [ cn "module-id" ] [ HH.text ("#" <> id) ] ]
  spacer = HH.div [ cn "spacer" ] []
  inputPlate = case inputs of
                   [] -> HH.div_ []
                   _ -> HH.div_ [HH.div [ cn "input-plate" ] $ inJack <$> inputs, spacer]
  outputPlate = case outputs of
                    [] -> HH.div_ []
                    _ -> HH.div_ [spacer, HH.div [ cn "output-plate" ] $ outJack <$> outputs]
  inJack {source, destination} = HH.div [ cn "jack" ] [ HH.div [ cn "source-section" ] [ HH.text source ], HH.div [ cn "destination-section" ] [ HH.text destination ] ]
  outJack output = HH.div [ cn "output jack" ] [ HH.div [ cn "destination-section" ] [ HH.text output ] ]

cn :: forall r i. String -> IProp (class :: String | r) i
cn s = HE.class_ $ ClassName s
