module Main where

import Prelude
import Effect (Effect)
import Effect.Class (class MonadEffect)
import Effect.Console (log)
import El as El
import Halogen as H
import Halogen.Aff (awaitBody, runHalogenAff)
import Halogen.HTML as HH
import Halogen.HTML.Events as HV
import Halogen.VDom.Driver (runUI)
import Space (produceGraph, sourceTag, testWorld1)

main :: Effect Unit
main =
  runHalogenAff do
    body <- awaitBody
    core <- H.liftEffect El.createCore
    -- _ <- H.liftEffect $ test
    runUI component core body

type State
  = { core :: El.Core, outputSelect :: Number, source :: El.Node, graph :: El.Node }

data Action
  = Nothing
  | Toggle

component :: forall query output m. MonadEffect m => H.Component query El.Core output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }

initialState :: El.Core -> State
initialState core = { core: core, outputSelect: 1.0, source: source, graph: El.quiet }
  where
  source = El.tapOut sourceTag $ (El.sample "test.wav" (El.train 0.1) 1.0)

render :: forall m. State -> H.ComponentHTML Action () m
render s = do
  HH.div_
    $ [ HH.button [ HV.onClick \_ -> Nothing ] [ HH.text "kuken" ]
      , HH.button [ HV.onClick \_ -> Toggle ] [ HH.text $ label s.outputSelect ]
      ]
  where
  label 1.0 = "Original"

  label _ = "Bouncy"

handleAction :: forall output m. MonadEffect m => Action -> H.HalogenM State Action () output m Unit
handleAction = case _ of
  Nothing -> do
    _ <- H.liftEffect $ log "Tracing"
    thing <- H.liftEffect $ produceGraph testWorld1 1000
    _ <- H.liftEffect $ log "Traced"
    core <- H.gets _.core
    outputSelect <- H.gets _.outputSelect
    source <- H.gets _.source
    core2 <- H.liftEffect $ El.renderMono core (El.select outputSelect thing source)
    H.modify_ \state -> state { core = core2, graph = thing }
  Toggle -> do
    H.modify_ \state -> state { outputSelect = flip state.outputSelect }
    outputSelect <- H.gets _.outputSelect
    source <- H.gets _.source
    core <- H.gets _.core
    graph <- H.gets _.graph
    core2 <- H.liftEffect $ El.renderMono core (El.select outputSelect graph source)
    H.modify_ \state -> state { core = core2 }
    where
    flip 0.0 = 1.0

    flip _ = 0.0
