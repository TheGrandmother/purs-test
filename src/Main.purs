module Main where

import Prelude
import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..))
import Data.Number (fromString)
import Debug as Debug
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

type Params
  = { gate :: Number, freq :: Number }

type State
  = { core :: El.Core, lines :: Array S.Line, gate :: Number, freq :: Number }

data Action
  = LineChange LineEvent
  | FreqChange String

component :: forall query output m. MonadEffect m => H.Component query El.Core output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }

initialState :: El.Core -> State
initialState core = { core: core, lines: [ S.makeLine "a", S.makeLine "b", S.makeLine "c" ], gate: 0.0, freq: 440.0 }

render :: forall m. State -> H.ComponentHTML Action () m
render state = do
  HH.div_
    [ HH.div_ $ mapWithIndex (lineWidget) state.lines
    , HH.input $ inputConfig \e -> FreqChange e
    , HH.text $ "Freq: " <> (show $ state.freq) <> "hz"
    ]
  where
  lineWidget no spec =
    HH.div [ HE.class_ $ ClassName "line-widget" ]
      [ HH.h4_ [ HH.text $ "Delay line " <> (show spec.tag) ]
      , HH.div [] [ HH.input $ inputConfig \e -> LineChange (S.LineEvent no Delay e), HH.text $ "delay: " <> (show $ spec.delay * 100.0) <> "ms" ]
      , HH.div [] [ HH.input $ inputConfig \e -> LineChange (S.LineEvent no Gain e), HH.text $ "Gain: " <> (show spec.gain) ]
      ]

  inputConfig ef = [ HE.type_ InputRange, HE.value "0.0", HE.max 1.0, HE.step $ Step 0.001, HV.onValueInput ef ]

handleAction :: forall output m. MonadEffect m => Action -> H.HalogenM State Action () output m Unit
handleAction = case _ of
  FreqChange f -> do
    case fromString f of
      Nothing -> H.modify_ \state -> state
      Just fr -> do
        state <- H.modify \state -> state { freq = fr * 880.0 }
        core2 <- H.liftEffect $ playLines state
        H.modify_ \_ -> state { core = core2 }
  LineChange e -> do
    state <- H.modify \state -> state { lines = S.updateLines e state.lines }
    core2 <- H.liftEffect $ playLines state
    H.modify_ \_ -> state { core = core2 }
  where
  playLines state = El.renderMono state.core $ S.pingu state.lines state.freq
