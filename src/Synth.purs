module Synth (pingu, delayLine, Line, LineParam(..), LineEvent(..), updateLines, makeLine) where

import Prelude

import Data.Array (foldl, length, modifyAt, (:))
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Data.Number (fromString)
import El as El

tc :: String -> Number -> Record ()
tc t v = El.const t v

pwmTrain :: Number -> Number -> El.Node
pwmTrain freq duty = El.sm $ El.le (El.ramp $ tc "f" freq) $ tc "d" duty

pulseGen :: Number -> Number -> Number -> El.Node
pulseGen pulseFreq duty freq = El.mul (El.cycle $ El.const "os_f" freq) (pwmTrain pulseFreq duty)

mix :: Array El.Node -> El.Node
mix l =
  let
    damp = 1.0 / (toNumber $ length l)
  in
    El.mul damp $ foldl (El.add) (El.const "_" 0.0) l

type Line
  = { tag :: String, gain :: Number, delay :: Number }

data LineParam
  = Gain
  | Delay

data LineEvent
  = LineEvent Int LineParam String

makeLine :: String -> Line
makeLine t = { tag: t, gain: 0.0, delay: 0.0 }

delayLine :: Line -> El.Node
delayLine l = El.mul (tc (l.tag <> "_g") l.gain) $ El.delay (tc (l.tag <> "_t") (ms (l.delay))) 0.0 (El.tapIn "balle")
  where
  ms t = (El.sampleRate * t) / 1000.0



updateLines :: LineEvent -> Array Line -> Array Line
updateLines (LineEvent no param _val) lines = case newLines of
  Nothing -> lines
  Just new -> new
  where
  newLines = do
    val <- fromString _val
    new <- modifyAt no (setParam param val) lines
    pure new

  setParam Gain val s = s { gain = val }

  setParam Delay val s = s { delay = val }

pingu :: (Array Line) -> Number -> Number -> Number -> El.Node
pingu lines freq duty rate =
  El.tapOut "balle"
    $ mix
    $ pg
    : (map (delayLine) lines)
  where
  pg = pulseGen rate (duty / 100.0) freq
