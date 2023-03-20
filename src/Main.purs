module Main where

import Prelude

import Data.Foldable (class Foldable, for_)
import Data.Int (toNumber)
import Data.List (List(..), fromFoldable, reverse, (..), (:))
import Data.List as List
import Data.List.NonEmpty as NE
import Data.Maybe (Maybe(..))
import Data.Traversable (for)
import Drawing (buildScaler, drawPoint, drawSolid, drawSource)
import Drawing as D
import Effect (Effect)
import Effect.Class (class MonadEffect)
import Effect.Console (log, logShow)
import Effect.Random (random)
import El as El
import Graphics.Canvas (fillPath, getCanvasDimensions, getCanvasElementById, getCanvasHeight, getCanvasWidth, getContext2D, rect, setFillStyle)
import Halogen as H
import Halogen.Aff (awaitBody, runHalogenAff)
import Halogen.HTML as HH
import Halogen.HTML.Events as HV
import Halogen.HTML.Properties as HE
import Halogen.VDom.Driver (runUI)
import Space (sourceTag)
import Space2D (getSegments)
import Space2D as S
import Vector as V
import Web.DOM.Element (fromEventTarget, getBoundingClientRect)
import Web.Event.Event (target)
import Web.UIEvent.MouseEvent as WebUi
import Widgets (createIntSlider, createSmoothSlider)

main :: Effect Unit
main =
  runHalogenAff do
    body <- awaitBody
    core <- H.liftEffect El.createCore
    runUI component core body

deHouse :: NE.NonEmptyList (Array Number)
deHouse =
  NE.appendFoldable (NE.singleton [ small, meh ])
    [ [ small, -1.0 * (big) ]
    , [ big, -1.0 * (big) ]
    , [ big, big ]
    , [ -1.1 * (big), 1.1 * big ]
    , [ -1.0 * (big), -1.0 * (big) ]
    , [ -1.0 * small, -1.0 * (big) ]
    , [ -2.0 * small, meh * 0.9 ]
    ]
  where
  big = 10.0

  meh = 8.0

  small = 1.0

testSolid :: S.Solid
testSolid = { ol: V.fromFoldable <$> deHouse }

type World =
  { solid :: S.Solid
  , origin :: V.Vector
  , source :: S.Source
  , scale :: Number
  }

drawWorld :: World -> Effect Unit
drawWorld world = do
  canvas' <- getCanvasElementById "canvas-elem"
  case canvas' of
    Nothing -> do
      log "Canvas not found"
      pure unit
    Just canvas -> do
      ctx <- getContext2D canvas
      setFillStyle ctx "#ddd"
      height <- getCanvasHeight canvas
      width <- getCanvasWidth canvas
      fillPath ctx
        $ rect ctx
            { x: 0.0
            , y: 0.0
            , width: width
            , height: height
            }
      dim <- getCanvasDimensions canvas
      let
        scaler = buildScaler world.scale dim
      drawSolid scaler ctx world.solid
      drawPoint scaler ctx world.origin
      drawSource scaler ctx world.source world.scale
      pure unit

renderTraces :: S.Options -> Int -> Int -> World -> Effect El.Node
renderTraces options count maxBounces world = do
  canvas' <- getCanvasElementById "canvas-elem"
  case canvas' of
    Nothing -> do
      log "Canvas not found"
      pure $ El.quiet
    Just canvas -> do
      ctx <- getContext2D canvas
      dim <- getCanvasDimensions canvas
      let
        scaler = buildScaler world.scale dim
      candidateTraces <- for (0 .. count) (\_ -> makeTrace options maxBounces world)
      let
        traces = dropMaybes candidateTraces
      log $ "Succesful paths: " <> show (List.length traces)
      for_ traces (\t -> (D.drawPathCrazy scaler ctx (reverse t)))
      let
        hitRate = (toNumber (List.length traces)) / (toNumber count)
      log $ "Hit rate: " <> show hitRate
      pure $ S.renderGraph traces 1.0

dropMaybes :: forall a f. Foldable f => f (Maybe a) -> List a
dropMaybes x = reverse $ _drop (fromFoldable x) Nil
  where
  _drop Nil acc = acc

  _drop (Nothing : rest) acc = _drop rest acc

  _drop ((Just a) : rest) acc = _drop rest (a : acc)

makeTrace :: S.Options -> Int -> World -> Effect (Maybe (List S.Step))
makeTrace options maxN world = do
  x <- random
  y <- random
  let
    ray = { o: world.origin, r: V.norm { x: x * 2.0 - 1.0, y: y * 2.0 - 1.0 } }
  S.trace options maxN ray world.source (getSegments world.solid)

type State =
  { core :: El.Core
  , outputSelect :: Number
  , source :: El.Node
  , graph :: El.Node
  , renderText :: String
  , count :: Int
  , bounces :: Int
  , world :: World
  , options :: S.Options
  }

data Action
  = Fuckall
  | Toggle
  | Init
  | SetRenderText String
  | SetCount Int
  | SetBounces Int
  | MouseBs WebUi.MouseEvent
  | SetRandom Number
  | ToggleHinting

component :: forall query output m. MonadEffect m => H.Component query El.Core output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction, initialize = Just Init }
    }

initialState :: El.Core -> State
initialState core =
  { core: core
  , outputSelect: 1.0
  , source: source
  , graph: El.quiet
  , renderText: "Render"
  , count: 50
  , bounces: 10
  , world: testWorld
  , options: { useHinting: false, randomFactor: 0.0 }
  }
  where
  source = El.tapOut sourceTag $ (El.sample "test.wav" (El.train 0.15) 1.0)

canvasDimension
  :: { x :: Int
     , y :: Int
     }
canvasDimension = { x: 600, y: 600 }

render :: forall m. State -> H.ComponentHTML Action () m
render s = do
  HH.div_
    [ HH.div_
        [ HH.button [ HV.onClick \_ -> Fuckall ] [ HH.text s.renderText ]
        , HH.button [ HV.onClick \_ -> Toggle ] [ HH.text $ label s.outputSelect ]
        ]
    , createIntSlider "Ray count" 1 750 s.count \v -> SetCount v
    , createIntSlider "Bounces" 2 20 s.bounces \v -> SetBounces v
    , createSmoothSlider "Randomness" "" 0.0 3.14 s.options.randomFactor \v -> SetRandom v
    , HH.div_ [ HH.button [ HV.onClick \_ -> ToggleHinting ] [ HH.text $ "Hinting is " <> boolToText s.options.useHinting ] ]
    , HH.canvas [ HE.id "canvas-elem", HE.width canvasDimension.x, HE.height canvasDimension.y, HV.onMouseDown \e -> MouseBs e ]
    ]
  where
  label 1.0 = "Toggle Original Sound"
  label _ = "Topggle Bounced Sound"
  boolToText false = "off"
  boolToText true = "on"

testWorld :: World
testWorld =
  { solid: testSolid
  , scale: 25.0
  , source: { o: { x: -5.5, y: -5.0 }, r: 2.0 }
  , origin: { x: 5.0, y: -2.0 }
  }

updateWorld :: { x :: Number, y :: Number } -> World
updateWorld origin = testWorld { origin = origin }

pixelToWorld :: World -> Int -> Number -> Number
pixelToWorld world max' abs = (abs - hMax) / hMax * otto
  where
  hMax = (toNumber max') / 2.0
  otto = hMax / world.scale

handleAction :: forall output m. MonadEffect m => Action -> H.HalogenM State Action () output m Unit
handleAction = case _ of
  Init -> do
    world <- H.gets _.world
    _ <- H.liftEffect $ drawWorld world
    H.modify_ \s -> s

  MouseBs e -> do
    case target $ WebUi.toEvent e of
      Just balls -> do
        case fromEventTarget balls of
          Just otto -> do
            position <- H.liftEffect $ getBoundingClientRect otto
            world <- H.gets _.world
            let converter = pixelToWorld world canvasDimension.x
            let
              newOrigin =
                { x: converter $ (toNumber $ WebUi.clientX e) - position.left
                , y: -1.0 * (converter $ (toNumber $ WebUi.clientY e) - position.top)
                }
            let newWorld = updateWorld newOrigin
            _ <- H.liftEffect $ drawWorld newWorld
            H.modify_ \state -> state
              { world = updateWorld newOrigin
              }
          Nothing -> do
            _ <- H.liftEffect $ logShow $ "no element from canvas"
            H.modify_ \s -> s

      Nothing -> do
        _ <- H.liftEffect $ logShow $ "no canvas"
        H.modify_ \s -> s

  SetRenderText s -> do
    H.modify_ \state -> state { renderText = s }

  SetBounces s -> do
    H.modify_ \state -> state { bounces = s }

  SetCount s -> do
    H.modify_ \state -> state { count = s }

  SetRandom s -> do
    H.modify_ \state -> state { options = state.options { randomFactor = s } }

  ToggleHinting -> do
    H.modify_ \state -> state { options = state.options { useHinting = not state.options.useHinting } }

  Fuckall -> do
    world <- H.gets _.world
    _ <- H.liftEffect $ drawWorld world
    count <- H.gets _.count
    bounces <- H.gets _.bounces
    options <- H.gets _.options
    thing <- H.liftEffect $ renderTraces options count bounces world
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
