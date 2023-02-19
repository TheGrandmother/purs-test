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
  --, smooth
  ) where

import Data.Function.Uncurried 

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


foreign import play :: Core ->  Effect Core

foreign import __cycle :: forall p. Fn1 p Node
foreign import __adsr :: forall p1 p2 p3 p4 p5. Fn5 p1 p2 p3 p4 p5 Node
foreign import __mul :: forall p1 p2. Fn2 p1 p2 Node
foreign import __meter :: forall p1 p2. Fn2 p1 p2 Node
foreign import __const :: forall p. Fn1 p Node
foreign import __smooth :: forall p. Fn1 p Node

mul :: forall p1 p2. p1 -> p2 -> Node
mul p1 p2 = runFn2 __mul p1 p2

cycle :: forall p1. p1 -> Node
cycle p = runFn1 __cycle p

-- smooth :: forall p1. p1 -> Node
-- smooth p = runFn1 __smooth p

adsr :: forall p1 p2 p3 p4 p5. p1 -> p2 -> p3 -> p4 -> p5 -> Node
adsr p1 p2 p3 p4 p5 = runFn5 __adsr p1 p2 p3 p4 p5

const :: String -> Number -> Node
const key val = runFn1 __const {key : key, value: val}

meter :: forall p. String -> p -> Node
meter name p = runFn2 __meter {name : name} p


