module Main where

import Prelude

import Effect (Effect)
import Effect.Class (class MonadEffect)
import El as El
import Halogen as H
import Halogen.Aff (awaitBody, runHalogenAff)
import Halogen.HTML as HH
import Halogen.HTML.Events as HV
import Halogen.VDom.Driver (runUI)
import Module (RackModule(..), Parameter(..))
import Module as M
import Widgets as W

main :: Effect Unit
main =
  runHalogenAff do
    body <- awaitBody
    core <- H.liftEffect El.createCore
    runUI component core body

type State
  = { core :: El.Core, rack :: Array RackModule }

data Action
  = Kuken String
  | SetControl M.Parameter

component :: forall query output m. MonadEffect m => H.Component query El.Core output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }

initialState :: El.Core -> State
initialState core = { core: core, rack: rack }

render :: forall m. State -> H.ComponentHTML Action () m
render state = do
  HH.div_ $ 
    [ HH.button [ HV.onClick \_ -> Kuken "aron" ] [ HH.text "kuken" ]
    ] <> ((W.moduleWidget (\p -> SetControl p)) <$> state.rack)


rack :: Array RackModule
rack = [
  Clock "0" {freq: Smooth "f" "hz" 0.0 0.0 0.5},
  BasicOsc "1" {tune: Smooth "f" "hz" 0.0 0.0 0.5} {freqIn: El.tapIn "4:out"},
  Vca "2" {controlIn: El.tapIn "0:out", sourceIn: El.tapIn "1:out"},
  Output "3" {volume: Smooth "vol" "hz" 0.0 0.0 1.0} {signalIn: El.tapIn "2:out"},
  BasicOsc "4" {tune: Smooth "tune" "oct" (-5.0) 5.0 (-5.0)} {freqIn: M.quiet}
]

handleAction :: forall output m. MonadEffect m => Action -> H.HalogenM State Action () output m Unit
handleAction = case _ of
  Kuken _ -> do
    core <- H.gets _.core
    core2 <- H.liftEffect $ El.renderMono core $ M.renderRack rack
    H.modify_ \state -> state {core = core2}
  _ -> H.modify_ \state -> state
