module Synth (pingu) where

import Prelude
import Data.Int (toNumber)
import Data.Array (foldl, length)
import El as El

pwmTrain :: Number -> Number -> El.Node
pwmTrain freq duty = El.sm $ El.le (El.ramp freq) duty

pulseGen :: Number -> El.Node
pulseGen pulseFreq = El.mul (mix [ El.cycle 440.0, El.mul 0.0 $ El.blepsquare 330.0 ]) (pwmTrain pulseFreq 0.02)

mix :: Array El.Node -> El.Node
mix l =
  let
    damp = 1.0 / (toNumber $ length l)
  in
    El.mul damp $ foldl (El.add) (El.const "_" 0.0) l

pingu :: El.Node
pingu =
  El.tapOut "balle"
    $ mix
        [ pg
        , simpleDelayLine 1.3 0.0067
        , simpleDelayLine 1.3 0.007
        , simpleDelayLine 1.4 0.0021
        ]
  where
  pg = pulseGen 0.5

  -- delayLfo f = El.add 500 $ El.mul 490 $ El.cycle f
  simpleDelayLine amp t = El.mul amp $ El.sdelay t (El.tapIn "balle")
