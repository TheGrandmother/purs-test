module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class (class MonadEffect)
import Effect.Random (random)
import El as El
import Halogen as H
import Halogen.Aff (awaitBody, runHalogenAff)
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.VDom.Driver (runUI)

main :: Effect Unit
main = runHalogenAff do
  body <- awaitBody
  core <- H.liftEffect El.createCore
  runUI component core body

type Params = {gate :: Number, freq :: Number}
type State = {core :: Maybe El.Core, params :: Params}

data Action = Regenerate | Play Number

component :: forall query output m. MonadEffect m => H.Component query El.Core output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }

initialState :: El.Core -> State
initialState core = {core : Just core, params : {gate : 0.0, freq : 0.0}}

render :: forall m. State -> H.ComponentHTML Action () m
render state = do
  let value = "Freq: " <> show state.params.freq <> " g8: " <> show state.params.gate
  HH.div_
    [ HH.p_
        [ HH.text ("Current value: " <> value) ]
    , HH.button
        [ HE.onClick \_ -> Regenerate ]
        [ HH.text "Fuck it up" ]
    , HH.p_ []
    , HH.button
        [ HE.onMouseDown \_ -> Play 1.0,  HE.onMouseUp \_ -> Play 0.00, HE.onTouchStart \_ -> Play 1.0, HE.onTouchEnd \_ -> Play 0.0]
        [ HH.text "Play" ]
    ]


handleAction :: forall output m. MonadEffect m => Action -> H.HalogenM State Action () output m Unit
handleAction = case _ of
  Regenerate -> do
    newNumber <- H.liftEffect random
    H.modify_ \state -> state {params = (state.params {freq = newNumber})}
  Play gate -> do
     fuckall <- H.gets _.core
     case fuckall of
      Nothing -> H.modify_ \state -> state
      Just core -> do
        params <- H.gets _.params
        core2 <- H.liftEffect $ El.renderMono core (
          let
            signal = (El.cycle (El.const "freq" (440.0+params.freq*440.0)))
            env = (El.meter "kuken" (El.adsr 1.5 0.1 0.7 3.0 (El.const "gate" (gate))))
          in El.mul signal env
        )
        H.modify_ \state -> state {core = Just core2, params = (state.params {gate = gate})}
