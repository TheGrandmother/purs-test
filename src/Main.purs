module Main where

import Prelude
import Data.Maybe (Maybe(..))
import Debug (trace)
import Effect (Effect)
import Effect.Class (class MonadEffect)
import El as El
import Halogen as H
import Halogen.Aff (awaitBody, runHalogenAff)
import Halogen.HTML as HH
import Halogen.HTML.Events as HV
import Halogen.HTML.Properties (InputType(..), StepValue(..))
import Halogen.HTML.Properties as HE
import Halogen.VDom.Driver (runUI)
import Synth as S
import Web.Event.Event (target, Event)

main :: Effect Unit
main =
  runHalogenAff do
    body <- awaitBody
    core <- H.liftEffect El.createCore
    runUI component core body

type Params
  = { gate :: Number, freq :: Number }

type State
  = { core :: Maybe El.Core, params :: Params }

data Action
  = Play Number
  | ParamChange String

component :: forall query output m. MonadEffect m => H.Component query El.Core output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }

initialState :: El.Core -> State
initialState core = { core: Just core, params: { gate: 0.0, freq: 0.0 } }

render :: forall m. State -> H.ComponentHTML Action () m
render state = do
  HH.div_
    [ HH.input [ HE.type_ InputRange, HE.max 1.0, HE.step $ Step 0.01, HV.onValueInput \e -> ParamChange e ]
    , HH.button
        [ HV.onMouseDown \_ -> Play 1.0
        , HV.onMouseUp \_ -> Play 0.00
        , HV.onTouchStart \_ -> Play 1.0
        , HV.onTouchEnd \_ -> Play 0.0
        ]
        [ HH.text "Play" ]
    ]

handleAction :: forall output m. MonadEffect m => Action -> H.HalogenM State Action () output m Unit
handleAction = case _ of
  ParamChange x -> trace (show x) \_ -> H.modify_ \state -> state
  Play gate -> do
    fuckall <- H.gets _.core
    case fuckall of
      Nothing -> H.modify_ \state -> state
      Just core -> do
        core2 <-
          H.liftEffect
            $ El.renderMono core
            $ S.pingu
        H.modify_ \state -> state { core = Just core2, params = (state.params { gate = gate }) }
