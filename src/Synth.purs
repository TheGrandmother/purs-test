module Synth (pingu, delayLfo, delayLine, Line, LineParam(..), LineEvent(..), updateLines, makeLine) where

import Prelude

import Data.Array (foldl, length, modifyAt, (:))
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Data.Number (fromString)
import El as El

pwmTrain :: Number -> Number -> El.Node
pwmTrain freq duty = El.sm $ El.le (El.ramp freq) duty

pulseGen :: Number -> El.Node
pulseGen pulseFreq = El.mul (mix [ El.cycle 880.0, El.mul 0.0 $ El.blepsquare 330.0 ]) (pwmTrain pulseFreq 0.01)

mix :: Array El.Node -> El.Node
mix l =
  let
    damp = 1.0 / (toNumber $ length l)
  in
    El.mul damp $ foldl (El.add) (El.const "_" 0.0) l

delayLfo :: Number -> Number -> El.Node
delayLfo f c = El.add c $ El.mul c $ El.cycle f


type Line = {tag :: String,  gain :: Number, delay :: Number}
data LineParam = Gain | Delay
data LineEvent = LineEvent Int LineParam String

makeLine :: String -> Line
makeLine t = {tag: t, gain:0.0, delay: 0.0}

delayLine :: Line -> El.Node
delayLine l = El.delay (El.const (l.tag <> "_t") (ms (l.delay * 100.0))) (El.const (l.tag <> "_g") l.gain) (El.tapIn "balle")
  where ms t = (El.sampleRate * t) / 1000.0


updateLines :: LineEvent -> Array Line -> Array Line
updateLines (LineEvent no param _val) lines = case newLines of
  Nothing -> lines
  Just new -> new
  where
    newLines = do
      val <- fromString _val
      new <- modifyAt no (setParam param val) lines
      pure new
    setParam Gain val s = s {gain = val}
    setParam Delay val s = s {delay = val}

-- case fromString _val of
--  Nothing -> lines
--  Just _ -> lines

pingu :: (Array Line) -> El.Node
pingu lines =
  El.tapOut "balle"
    $ mix $ pg : (map (delayLine) lines)
  where
  pg = pulseGen 0.5

