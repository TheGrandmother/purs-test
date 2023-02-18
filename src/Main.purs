module Main where

import Effect (Effect)
import El as El
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.VDom.Driver (runUI)
import Prelude
import Data.Maybe

main :: Effect Unit
main =
  HA.runHalogenAff do
    body <- HA.awaitBody
    runUI component unit body

data Action
  = Increment
  | Decrement
  | Plej
  | Init

type State
  = { val :: Int, core :: El.Core, ctx :: El.Ctx }

-- otto :: Effect Unit
-- otto = do
--   core <- kuken
--   _ <- El.onCoreLoad core El.flerp
--   pure unit
--   where
--   kuken :: Effect El.Core
--   kuken = Effect El.createCore
component :: forall output a b c. H.Component output a b c
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }
  where
  initialState :: forall t. t -> State
  initialState _ = { val: 0, core: El.createCore, ctx: El.createCtx }

  render state =
    HH.div_
      [ HH.button [ HE.onClick \_ -> Decrement ] [ HH.text "-" ]
      , HH.div_ [ HH.text $ show state ]
      , HH.button [ HE.onClick \_ -> Increment ] [ HH.text "+" ]
      , HH.button [ HE.onClick \_ -> Plej ] [ HH.text "plej" ]
      ]

  play :: State -> State
  play state = do
    let
      _ = El.play state.core state.ctx
    state

  handleAction = case _ of
    Increment -> H.modify_ \state -> state { val = state.val + 1 }
    Decrement -> H.modify_ \state -> state { val = state.val - 1 }
    Plej -> H.modify_ play
    Init ->
      H.modify \state -> do
        _ <- H.liftEffect $ El.onCoreLoad El.createCore El.flerp
        H.modify_ \state -> state { val = state.val - 1 }

-- Init ->
--   H.modify \state -> do
--     _ <- El.onCoreLoad state.core El.flerp
--     pure state
