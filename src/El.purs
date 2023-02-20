module El
  ( Core
  , Node
  , createCore
  , onCoreLoad
  , flerp
  , play
  , renderMono
  , render
  , cycle
  , adsr
  , mul
  , meter
  , const
  , phasor
  , le
  , ramp
  , smooth
  , sm
  , sdelay
  , add
  , tapIn
  , tapOut
  , highpass
  , lowpass
  , blepsquare
  , delay
  ) where

import Prelude
import Data.Function.Uncurried (Fn1, Fn2, Fn3, Fn4, Fn5, runFn1, runFn2, runFn3, runFn4, runFn5)
import Data.Int (floor)
import Effect (Effect)

type Core
  = {}

type Node
  = {}

foreign import createCore :: Effect Core

foreign import flerp :: Core -> Core

foreign import onCoreLoad :: Core -> (Core -> Core) -> Effect Core

foreign import render :: forall p1 p2. Core -> p1 -> p2 -> Effect Core

foreign import renderMono :: forall p. Core -> p -> Effect Core

foreign import play :: Core -> Effect Core

foreign import __cycle :: forall p. Fn1 p Node

foreign import __blepsquare :: forall p. Fn1 p Node

foreign import __adsr :: forall p1 p2 p3 p4 p5. Fn5 p1 p2 p3 p4 p5 Node

foreign import __mul :: forall p1 p2. Fn2 p1 p2 Node

foreign import __add :: forall p1 p2. Fn2 p1 p2 Node

foreign import __meter :: forall p1 p2. Fn2 p1 p2 Node

foreign import __le :: forall p1 p2. Fn2 p1 p2 Node

foreign import __const :: forall p. Fn1 p Node

foreign import __smooth :: forall p1 p2. Fn2 p1 p2 Node

foreign import __sm :: forall p. Fn1 p Node

foreign import __sr :: Node

foreign import __phasor :: forall p1 p2. Fn2 p1 p2 Node

foreign import __sdelay :: forall p1 p2. Fn2 p1 p2 Node

foreign import __tapIn :: forall p1. Fn1 p1 Node

foreign import __tapOut :: forall p1 p2. Fn2 p1 p2 Node

foreign import __highpass :: forall p1 p2 p3. Fn3 p1 p2 p3 Node

foreign import __lowpass :: forall p1 p2 p3. Fn3 p1 p2 p3 Node

foreign import __delay :: forall p1 p2 p3 p4. Fn4 p1 p2 p3 p4 Node

foreign import sampleRate :: Number

highpass :: forall p1 p2 p3. p1 -> p2 -> p3 -> Node
highpass p1 p2 p3 = runFn3 __highpass p1 p2 p3

lowpass :: forall p1 p2 p3. p1 -> p2 -> p3 -> Node
lowpass p1 p2 p3 = runFn3 __lowpass p1 p2 p3

tapIn :: forall p1. Show p1 => p1 -> Node
tapIn name = runFn1 __tapIn { name: show name }

tapOut :: forall p1 p2. Show p1 => p1 -> p2 -> Node
tapOut name node = runFn2 __tapOut { size: 512, name: show name } node

mul :: forall p1 p2. p1 -> p2 -> Node
mul p1 p2 = runFn2 __mul p1 p2

add :: forall p1 p2. p1 -> p2 -> Node
add p1 p2 = runFn2 __add p1 p2

le :: forall p1 p2. p1 -> p2 -> Node
le p1 p2 = runFn2 __le p1 p2

cycle :: forall p1. p1 -> Node
cycle p = runFn1 __cycle p

blepsquare :: forall p1. p1 -> Node
blepsquare p = runFn1 __blepsquare p

phasor :: forall p1 p2. p1 -> p2 -> Node
phasor p1 p2 = runFn2 __phasor p1 p2

smooth :: forall p1 p2. p1 -> p2 -> Node
smooth p1 p2 = runFn2 __smooth p1 p2

sdelay :: forall p2. Number -> p2 -> Node
sdelay p1 p2 = runFn2 __sdelay { size: s } p2
  where
  s = floor (p1 * sampleRate)

delay :: forall p1 p2 p3. p1 -> p2 -> p3 -> Node
delay p1 p2 p3 = runFn4 __delay { size: sampleRate * 2.0 } p1 p2 p3

sm :: forall p1. p1 -> Node
sm p1 = runFn1 __sm p1

ramp :: forall p1. p1 -> Node
ramp p1 = runFn2 __phasor p1 0.0

adsr :: forall p1 p2 p3 p4 p5. p1 -> p2 -> p3 -> p4 -> p5 -> Node
adsr p1 p2 p3 p4 p5 = runFn5 __adsr p1 p2 p3 p4 p5

const :: String -> Number -> Node
const key val = runFn1 __const { key: key, value: val }

meter :: forall p. String -> p -> Node
meter name p = runFn2 __meter { name: name } p
