module Module where

import Prelude

import El as El

data Parameter = Smooth String String Number Number Number


{-
  A module consists of a rendering function, a set ofg parameters, a set of inputs and a set of outputs.
    The inputs are unbound nodes (almost always tap ins)
    Parameters are datatypes with an name for keying and a plain old numeric value. these are mapepd to widgets
    The output are a list of names of tapOut nodes
    A module has a rendering function that takes a set of parameters, inpput nodes, and an id that returns a node
-}

quiet :: El.Node
quiet = El.const "_quiet_" 0.0

paramToConst :: Parameter -> String -> El.Node
paramToConst (Smooth name _ _ _ value) moduleId = El.const (moduleId <> ":" <> name) value

basicOsc :: String -> Parameter -> El.Node -> El.Node
basicOsc id tune input = El.tapOut (id <> ":out") $ El.blepsquare f
  where
  f = El.add (paramToConst tune id) input

output :: String -> Parameter -> El.Node -> El.Node
output id volume input = El.mul (input) (paramToConst volume id)

clock :: String -> Parameter -> El.Node
clock id freq = El.tapOut (id <> ":out") $ El.train $ paramToConst freq id

-- data Module = Module (Array Parameter) (Array El.Node) (Array El.Node) Int

type Id = (forall a. Show a => a)
type Printable = (forall a. Show a => a)

data Module
  = Clock Id {freq :: Parameter}
  | Output Id {volume :: Parameter} {signalIn :: El.Node}
  | BasicOsc Id {tune :: Parameter} {freqIn :: El.Node}

render :: Module ->  El.Node
render (Clock id {freq}) = El.tapOut (id <> ":out") $ El.train $ paramToConst freq id
render (Output id {volume} {signalIn}) = El.mul (signalIn) (paramToConst volume id)
render (BasicOsc id {tune} {freqIn}) =
  let
    f = El.add (paramToConst tune id) freqIn
  in
    El.tapOut (id <> ":out") $ El.blepsquare $ cvToHz f 440.0



class Input :: forall k. k -> Constraint
class Input a
instance fieldNode :: Input Number
instance inputNode :: Input El.Node

cvToHz :: forall x y. Input x => x -> Input y => y -> El.Node
cvToHz cv base = El.mul (El.pow 2 cv) base
