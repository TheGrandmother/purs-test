module Materials (
  Material (..),
  absorbtionFreq,
  absorbtionSpectra,
  speedOfSound,
  baseAlpha,
  impedance,
  reflectionCoefficient,
  absorbtionCoefficient
) where

import Prelude

import Data.Number (log)



data Material
  = AcousticTile
  | Brick
  | Fabric
  | Marble
  | Concrete
  | Wood
  | Air


absorbtionFreq :: Array Number
absorbtionFreq = [125.0 , 250.0, 500.0, 1000.0, 2000.0]

absorbtionSpectra :: Material -> Array Number
absorbtionSpectra Air = [ 1.0, 1.0, 1.0, 1.0, 1.0 ]
absorbtionSpectra AcousticTile = [ 0.80 ,0.90 ,0.90 ,0.95 ,0.90 ]
absorbtionSpectra Brick = [ 0.03 ,0.03 ,0.03 ,0.04 ,0.05 ]
absorbtionSpectra Fabric = [ 0.15 ,0.35 ,0.55 ,0.75 ,0.70 ]
absorbtionSpectra Marble = [ 0.01 ,0.01 ,0.01 ,0.01 ,0.02 ]
absorbtionSpectra Concrete = [ 0.01 ,0.01 ,0.01 ,0.02 ,0.02 ]
absorbtionSpectra Wood = [ 0.15 ,0.11 ,0.10 ,0.07 ,0.06 ]

speedOfSound :: Material -> Number
speedOfSound AcousticTile = 518.0 -- ish
speedOfSound Brick = 4200.0
speedOfSound Fabric = 360.0 -- not really
speedOfSound Marble = 3810.0
speedOfSound Concrete = 3700.0
speedOfSound Wood = 3600.0
speedOfSound Air = 343.0

density :: Material -> Number
density Air = 0.001
density Fabric = 0.1
density AcousticTile = 0.2 -- ish
density Wood = 0.700
density Brick = 2.0
density Marble = 2.8
density Concrete = 1.7

baseAlpha :: Number
baseAlpha = div (-1.0 * log(0.5)) 440.0 -- from my ass, this was pulled

impedance :: Material -> Number
impedance m = speedOfSound m * density m

reflectionCoefficient :: Material -> Material -> Number
reflectionCoefficient m1 m2 = div (impedance m2 - impedance m1) (impedance m2 + impedance m1)

absorbtionCoefficient :: Number -> Number
absorbtionCoefficient rc = 1.0 - rc * rc
