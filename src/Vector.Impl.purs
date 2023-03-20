module Vector.Impl where

import Prelude
import Data.Foldable (class Foldable, indexl)
import Data.Maybe (Maybe(..))
import Data.Number (sin, sqrt, cos)
import Debug (traceM)

type Vector = { x :: Number, y :: Number }

unit :: Vector
unit = { x: 1.0, y: 1.0 }

add :: Vector -> Vector -> Vector
add v1 v2 = { x: v1.x + v2.x, y: v1.y + v2.y }

sub :: Vector -> Vector -> Vector
sub v1 v2 = { x: v1.x - v2.x, y: v1.y - v2.y }

dot :: Vector -> Vector -> Number
dot v1 v2 = v1.x * v2.x + v1.y * v2.y

scale :: Number -> Vector -> Vector
scale n v = { x: v.x * n, y: v.y * n }

norm :: Vector -> Vector
norm v = scale (1.0 / (abs v)) v

abs :: Vector -> Number
abs v = sqrt $ dot v v

rotate :: Vector -> Number -> Vector
rotate { x, y } a =
  { x: x * ca - y * sa
  , y: x * sa + y * ca
  }
  where
  sa = sin a

  ca = cos a

normal :: Vector -> Vector
normal { x, y } = { x: -1.0 * y, y: x }

reflect :: Vector -> Vector -> Vector
reflect v n = v' - scale 2.0 (scale (dot n' v') n')
  where
  v' = norm v

  n' = norm n

fromFoldable :: forall f. Foldable f => f Number -> Vector
fromFoldable l = { x: fuckall $ indexl 0 l, y: fuckall $ indexl 1 l }
  where
  fuckall x = case x of
    Just n -> n
    Nothing -> 0.0

--
-- MATRIX CRAP
--
type Matrix = { x1 :: Number, y1 :: Number, x2 :: Number, y2 :: Number }

det :: Matrix -> Number
det { x1, y1, x2, y2 } = x1 * y2 - y1 * x2

fromVectors :: Vector -> Vector -> Matrix
fromVectors r p =
  { x1: r.x
  , y1: -1.0 * p.x
  , x2: r.y
  , y2: -1.0 * p.y
  }

adj :: Matrix -> Matrix
adj { x1, y1, x2, y2 } = { x1: y2, y1: -1.0 * y1, x2: -1.0 * x2, y2: x1 }

scale' :: Number -> Matrix -> Matrix
scale' n { x1, y1, x2, y2 } = { x1: x1 * n, y1: y1 * n, x2: x2 * n, y2: y2 * n }

vecMul :: Matrix -> Vector -> Vector
vecMul { x1, y1, x2, y2 } { x, y } =
  { x: x1 * x + y1 * y
  , y: x2 * x + y2 * y
  }

inv :: Matrix -> Maybe Matrix
inv m =
  if closeToZero d then
    Nothing
  else
    Just (scale' (1.0 / d) (adj m))
  where
  d = det m

solveSys :: Matrix -> Vector -> Maybe Vector
solveSys m b = do
  invM <- inv m
  pure $ vecMul invM b

closeToZero :: Number -> Boolean
closeToZero x = x < 0.0001 && x > -0.0001
