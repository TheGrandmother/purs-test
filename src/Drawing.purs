module Drawing where

import Prelude
import Data.Foldable (class Foldable, for_, traverse_)
import Data.FoldableWithIndex (class FoldableWithIndex, forWithIndex_)
import Data.Int (toNumber)
import Data.List (List(..), fromFoldable, (:))
import Data.List.NonEmpty (head, tail)
import Data.Number as Number
import Data.Number.Format (precision, toStringWith)
import Effect (Effect)
import Graphics.Canvas as C
import Space2D as S
import Vector (scale)
import Vector as V

type Scaler = (V.Vector -> V.Vector)

flipY :: V.Vector -> V.Vector
flipY v = { x: v.x, y: -1.0 * v.y }

buildScaler :: Number -> C.Dimensions -> (V.Vector -> V.Vector)
buildScaler s dim = \v -> s `scale` (flipY v) + dimVec
  where
  dimVec = (dim.width / 2.0) `scale` V.unit

drawSolid :: Scaler -> C.Context2D -> S.Solid -> Effect Unit
drawSolid scaler ctx s =
  C.withContext ctx
    $ do
        C.setFillStyle ctx "#080810"
        C.setLineWidth ctx 3.0
        let
          vecs = scaler <$> s.ol

          h = head vecs

          rest = tail vecs
        C.strokePath ctx
          $ do
              C.moveTo ctx h.x h.y
              traverse_ (\v -> C.lineTo ctx v.x v.y) rest
              C.closePath ctx
        pure unit

drawPoint :: Scaler -> C.Context2D -> V.Vector -> Effect Unit
drawPoint scaler ctx v =
  C.withContext ctx
    $ do
        C.setFillStyle ctx "#a31a08"
        let
          o = scaler v
        let
          path =
            C.arc ctx
              { x: o.x
              , y: o.y
              , radius: 5.0
              , start: 0.0
              , end: 2.0 * Number.pi
              , useCounterClockwise: false
              }
        C.fillPath ctx path
        pure unit

drawSource :: Scaler -> C.Context2D -> S.Source -> Number -> Effect Unit
drawSource scaler ctx source scale =
  C.withContext ctx
    $ do
        C.setFillStyle ctx "#78d703"
        let
          o = scaler source.o
        let
          path =
            C.arc ctx
              { x: o.x
              , y: o.y
              , radius: source.r * scale
              , start: 0.0
              , end: 2.0 * Number.pi
              , useCounterClockwise: false
              }
        C.fillPath ctx path
        pure unit

drawRay :: Scaler -> C.Context2D -> S.Ray -> Effect Unit
drawRay scaler ctx r =
  C.withContext ctx
    $ do
        let
          o = scaler r.o
        let
          end = o + (15.0 `scale` (V.norm $ flipY r.r))
        C.setFillStyle ctx "#08a810"
        C.setLineWidth ctx 3.0
        C.setLineCap ctx C.Round
        C.strokePath ctx
          $ do
              C.moveTo ctx o.x o.y
              C.lineTo ctx end.x end.y
        pure unit

drawPath :: forall f r. Functor f => Foldable f => Scaler -> C.Context2D -> (f { p :: V.Vector | r }) -> Effect Unit
drawPath scaler ctx path =
  C.withContext ctx
    $ do
        C.setStrokeStyle ctx "#04091080"
        C.setLineWidth ctx 1.0
        C.strokePath ctx $ for_ (scaleIt <$> path) (\p' -> C.lineTo ctx p'.p.x p'.p.y)
        pure unit
  where
  scaleIt segment = segment { p = scaler segment.p }

drawPathCrazy :: forall f r. Functor f => FoldableWithIndex Int f => Scaler -> C.Context2D -> (f { p :: V.Vector | r }) -> Effect Unit
drawPathCrazy scaler ctx path =
  C.withContext ctx
    $ do
        C.setStrokeStyle ctx "rgba(35, 26, 18, 0.8)"
        C.setLineWidth ctx 1.0
        let
          scaled = (scaleIt <$> path)
        forWithIndex_ (makeThing (fromFoldable scaled) Nil)
          ( \i -> \orka ->
              C.withContext ctx $ C.strokePath ctx
                $ do
                    setStyle i
                    for_ orka \p' -> C.lineTo ctx p'.p.x p'.p.y
          )
        pure unit
  where
  setStyle i = C.setStrokeStyle ctx ("rgba(35, 26, 18, " <> (nice i) <> ")")

  nice x
    | x > 10 = "0.01"

  nice x = toStringWith (precision 3) (((toNumber (x)) / 10.0) * 0.8)

  scaleIt segment = segment { p = scaler segment.p }

  makeThing Nil acc = acc

  makeThing (a : rest) Nil = makeThing rest ((a : Nil) : Nil)

  makeThing (a : rest) ((b : Nil) : acc) = makeThing rest ((a : Nil) : (a : b : Nil) : acc)

  makeThing _ _ = Nil
