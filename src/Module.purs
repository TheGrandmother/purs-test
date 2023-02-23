module Module where

import Prelude
import El as El

data Parameter
  = Smooth String String Number Number Number

paramToConst :: Parameter -> String -> El.Node
paramToConst (Smooth name _ _ _ value) moduleId = El.const (moduleId <> ":" <> name) value

basicOsc :: String -> Parameter -> El.Node
basicOsc id tune = El.tapOut (id <> ":out") $ El.blepsquare f
  where
  f = El.add (paramToConst tune id) (El.tapIn (id <> ":freq"))

output :: String -> Parameter -> El.Node
output id volume = El.tapOut (id <> ":out") $ El.mul $ paramToConst volume id

clock :: String -> Parameter -> El.Node
clock id freq = El.tapOut (id <> ":out") $ El.train $ paramToConst freq id
