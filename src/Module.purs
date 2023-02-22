module Module where

import El as El

data Parameter
  = Smooth String Number Number Number

basicOsc :: Record ()
basicOsc = El.blepsquare f
  where
  f = El.add (El.tapIn "tune_in") (El.tapIn "f_in")
