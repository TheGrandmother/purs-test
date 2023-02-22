module Main where

import Prelude
import Data.Array (length, mapWithIndex, (..))
import Data.Int (floor, toNumber)
import Data.Maybe (Maybe(..))
import Data.Number (fromString)
import Data.Number.Format (fixed, toStringWith)
import Effect (Effect)
import Effect.Class (class MonadEffect)
import El as El
import Halogen (ClassName(..))
import Halogen as H
import Halogen.Aff (awaitBody, runHalogenAff)
import Halogen.HTML as HH
import Halogen.HTML.Events as HV
import Halogen.HTML.Properties (InputType(..), StepValue(..))
import Halogen.HTML.Properties as HE
import Halogen.VDom.Driver (runUI)
import Synth (LineParam(..), LineEvent)
import Synth as S

main :: Effect Unit
main =
  runHalogenAff do
    body <- awaitBody
    core <- H.liftEffect El.createCore
    runUI component core body

type State
  = { core :: El.Core, lines :: Array S.Line, gate :: Number, freq :: Number, duty :: Number, rate :: Number }

data Action
  = LineChange LineEvent
  | ParamUpdate String String
  | SliderCount String

component :: forall query output m. MonadEffect m => H.Component query El.Core output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }

initialState :: El.Core -> State
initialState core = { core: core, lines: lineMaker 7, gate: 0.0, freq: 440.0, duty: 3.0, rate: 0.8 }

lineMaker :: Int -> Array S.Line
lineMaker n = map (\m -> S.makeLine (show m)) (0 .. (n - 1))

render :: forall m. State -> H.ComponentHTML Action () m
render state = do
  HH.div_
    [ HH.div [ HE.class_ $ ClassName "controller-box" ]
        [ slideWidget "Base f" state.freq "hz" [ 110.0, 10000.0 ] \e -> (ParamUpdate "freq" e)
        , slideWidget "Duty" state.duty "%" [ 0.0, 50.0 ] \e -> (ParamUpdate "duty" e)
        , slideWidget "Rate" state.rate "hz" [ 0.0, 5.0 ] \e -> (ParamUpdate "rate" e)
        -- , slideWidget "Lines" (toNumber $ length state.lines) "" [1.0, 10.0, 1.0] \e -> (SliderCount e)
        ]
    , HH.div_ $ mapWithIndex (lineWidget) state.lines
    ]
  where
  lineWidget no spec =
    HH.div [ HE.class_ $ ClassName "controller-box line-widget" ]
      [ slideWidget "Delay" spec.delay "ms" [ 0.1, 200.0 ] \e -> LineChange (S.LineEvent no Delay e)
      , slideWidget "Gain" spec.gain "" [ 0.0, 2.0 ] \e -> LineChange (S.LineEvent no Gain e)
      ]

slideWidget :: forall w i. String -> Number -> String -> Array Number -> (String -> i) -> HH.HTML w i
slideWidget name val unit [ min, max, step ] fn = HH.div [ HE.class_ $ ClassName "slide-widget" ] [ HH.span_ [ HH.text name ], slider min max step val fn, HH.span_ [ HH.text $ rounded <> unit ] ]
  where
  rounded = toStringWith (fixed 3) val

slideWidget name val unit [ min, max ] fn = slideWidget name val unit [ min, max, 0.001 ] fn

slideWidget name val unit _ fn = slideWidget name val unit [ 0.0, 1.0, 0.001 ] fn

slider :: forall b w. Number -> Number -> Number -> Number -> (String -> b) -> HH.HTML w b
slider min max step value fn = HH.input [ HE.type_ InputRange, HE.value (show value), HE.max max, HE.min min, HE.step $ Step step, HV.onValueInput fn ]

handleAction :: forall output m. MonadEffect m => Action -> H.HalogenM State Action () output m Unit
handleAction = case _ of
  SliderCount _c -> do
    case fromString _c of
      Just c -> do
        state <- H.modify \state -> state { lines = lineMaker (floor c) }
        core2 <- H.liftEffect $ playLines state
        H.modify_ \_ -> state { core = core2 }
      Nothing -> H.modify_ \state -> state
  ParamUpdate n v -> do
    case fromString v of
      Nothing -> H.modify_ \state -> state
      Just fr -> do
        state <-
          H.modify \state -> case n of
            "freq" -> state { freq = fr }
            "duty" -> state { duty = fr }
            "rate" -> state { rate = fr }
            _ -> state
        core2 <- H.liftEffect $ playLines state
        H.modify_ \_ -> state { core = core2 }
  LineChange e -> do
    state <- H.modify \state -> state { lines = S.updateLines e state.lines }
    core2 <- H.liftEffect $ playLines state
    H.modify_ \_ -> state { core = core2 }
  where
  playLines state = El.renderMono state.core $ S.pingu state.lines state.freq state.duty state.rate
