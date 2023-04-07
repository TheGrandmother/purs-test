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
  , ms2samps
  , sampleRate
  , sample
  , train
  , pow
  , getProps
  , quiet
  , mix
  , select
  , nodeCount
  , maxDepth
  ) where

import Data.Foldable (class Foldable, foldl, length)
import Data.Function.Uncurried (Fn1, Fn2, Fn3, Fn4, Fn5, runFn1, runFn2, runFn3, runFn4, runFn5)
import Data.Int (floor, toNumber)
import Data.Unit (Unit)
import Effect (Effect)
import Foreign.Object (Object)
import Prelude (class Show, show, ($), (*), (/))

type Core
  = {}

data Node
  = Void

foreign import _log :: forall a. a -> String

instance showNode :: Show Node where
  show n = _log n

foreign import createCore :: Effect Core

foreign import flerp :: Core -> Core

foreign import onCoreLoad :: Core -> (Core -> Core) -> Effect Core

foreign import render :: forall p1 p2. Core -> p1 -> p2 -> Effect Core

foreign import renderMono :: Core -> Node -> Effect Core

foreign import play :: Core -> Effect Core

foreign import __cycle :: forall p. Fn1 p Node

foreign import __blepsquare :: forall p. Fn1 p Node

foreign import __adsr :: forall p1 p2 p3 p4 p5. Fn5 p1 p2 p3 p4 p5 Node

foreign import __mul :: forall p1 p2. Fn2 p1 p2 Node

foreign import __pow :: forall p1 p2. Fn2 p1 p2 Node

foreign import __add :: forall p1 p2. Fn2 p1 p2 Node

foreign import __train :: forall p1. Fn1 p1 Node

foreign import __meter :: forall p1 p2. Fn2 p1 p2 Node

foreign import __le :: forall p1 p2. Fn2 p1 p2 Node

foreign import __const :: forall p. Fn1 p Node

foreign import __smooth :: forall p1 p2. Fn2 p1 p2 Node

foreign import __sm :: forall p. Fn1 p Node

foreign import __sr :: Node

foreign import __phasor :: forall p1 p2. Fn2 p1 p2 Node

foreign import __sdelay :: forall p1 p2. Fn2 p1 p2 Node

foreign import __tapIn :: forall p1. Fn1 p1 Node

foreign import __ms2samps :: forall p1. Fn1 p1 Number

foreign import __tapOut :: forall p1 p2. Fn2 p1 p2 Node

foreign import __highpass :: forall p1 p2 p3. Fn3 p1 p2 p3 Node

foreign import __lowpass :: forall p1 p2 p3. Fn3 p1 p2 p3 Node

foreign import __delay :: forall p1 p2 p3 p4. Fn4 p1 p2 p3 p4 Node

foreign import __sample :: forall p1 p2 p3. Fn3 p1 p2 p3 Node

foreign import __select :: forall p1 p2 p3. Fn3 p1 p2 p3 Node

foreign import sampleRate :: Number

foreign import getProps :: forall a. Node -> Object a

foreign import maxDepth :: Node -> Number

foreign import nodeCount :: Node -> Number

highpass :: forall p1 p2 p3. p1 -> p2 -> p3 -> Node
highpass p1 p2 p3 = runFn3 __highpass p1 p2 p3

lowpass :: forall p1 p2 p3. p1 -> p2 -> p3 -> Node
lowpass p1 p2 p3 = runFn3 __lowpass p1 p2 p3

tapIn :: forall p1. Show p1 => p1 -> Node
tapIn name = runFn1 __tapIn { name: show name }

train :: forall p1. p1 -> Node
train freq = runFn1 __train freq

tapOut :: forall p1 p2. Show p1 => p1 -> p2 -> Node
tapOut name node = runFn2 __tapOut { size: 512, name: show name } node

mul :: forall p1 p2. p1 -> p2 -> Node
mul p1 p2 = runFn2 __mul p1 p2

pow :: forall p1 p2. p1 -> p2 -> Node
pow p1 p2 = runFn2 __pow p1 p2

add :: forall p1 p2. p1 -> p2 -> Node
add p1 p2 = runFn2 __add p1 p2

le :: forall p1 p2. p1 -> p2 -> Node
le p1 p2 = runFn2 __le p1 p2

cycle :: forall p1. p1 -> Node
cycle p = runFn1 __cycle p

ms2samps :: forall p1. p1 -> Number
ms2samps p = runFn1 __ms2samps p

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

sample :: forall p2 p3. String -> p2 -> p3 -> Node
sample file gate pitch = runFn3 __sample { path: file } gate pitch

select :: forall p1 p2 p3. p1 -> p2 -> p3 -> Node
select p1 p2 p3 = runFn3 __select p1 p2 p3

quiet :: Node
quiet = const "___quiet___" 0.0

mix :: forall f. Foldable f => f Node -> Node
mix l =
  let
    damp = 1.0 / (toNumber $ length l)
  in
    mul damp $ foldl (add) (const "_" 0.0) l
