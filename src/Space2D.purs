module Space2D where

import Prelude
import Data.Foldable (foldM, foldl)
import Data.Int (toNumber)
import Data.List (List(..), length, reverse, (:))
import Data.List.NonEmpty (head, toList)
import Data.List.Types (NonEmptyList)
import Data.Maybe (Maybe(..))
import Data.Number (pow, sqrt)
import Data.Tuple (Tuple(..))
import Debug (traceM)
import Effect (Effect)
import Effect.Random (random)
import El as El
import Vector as V

type Segment = { p0 :: V.Vector, p1 :: V.Vector } -- Mat is material behind normal

type Solid =
  { ol :: NonEmptyList (V.Vector)
  }

getSegments :: Solid -> List Segment
getSegments { ol } = reverse $ _getSegments (toList ol) Nil
  where
  start = head ol

  makeSegment a b = { p0: a, p1: b }

  _getSegments (a : b : Nil) acc = (makeSegment b start : makeSegment a b : acc)

  _getSegments (a : b : rest) acc = _getSegments (b : rest) (makeSegment a b : acc)

  _getSegments _ _ = (makeSegment (V.fromFoldable [ 0.0, 0.0 ]) (V.fromFoldable [ 0.0, 0.0 ])) : Nil

type Ray = { o :: V.Vector, r :: V.Vector }

toRay :: Segment -> Ray
toRay { p0, p1 } = { o: p0, r: p1 - p0 }

type Hit = { seg :: Segment, t :: Number }

findIntersection :: Ray -> (List Segment) -> Maybe Hit
findIntersection r segs = do
  lol <- foldM (getClosest) { seg: { p0: V.unit, p1: V.unit }, t: 100000000.0 } segs
  pure lol
  where
  getClosest :: Hit -> Segment -> Maybe Hit
  getClosest current seg = closestHit (Just current) (iTest seg)

  iTest seg = intersectTest r seg

closestHit :: Maybe Hit -> Maybe Hit -> Maybe Hit
closestHit Nothing Nothing = Nothing

closestHit Nothing (Just h) = Just h

closestHit (Just h) Nothing = Just h

closestHit (Just h1) (Just h2)
  | h1.t < h2.t = Just h1

closestHit _ (Just h2) = Just h2

intersectTest :: Ray -> Segment -> Maybe Hit
intersectTest r s = do
  sol <- intersect r (toRay s)
  t <- gtz sol.x
  _ <- neat sol.y
  pure $ { seg: s, t: t }
  where
  gtz x
    | x > 0.001 = Just x

  gtz _ = Nothing

  neat x
    | x > -0.001 && x < 1.0001 = Just x

  neat _ = Nothing

intersect :: Ray -> Ray -> Maybe V.Vector
intersect r s = V.solveSys m b
  where
  m = V.fromVectors r.r s.r

  b = s.o - r.o

type Source = { o :: V.Vector, r :: Number }

intersectSource :: Ray -> Source -> Maybe Number
intersectSource ray source =
  if d <= source.r && (V.dot ray.r u) >= 0.001 then
    Just $ (V.abs u1) - m
  else
    Nothing
  where
  u = source.o - ray.o

  u1 = V.scale (V.dot u ray.r) ray.r

  d = V.abs (u - u1)

  m = sqrt (source.r * source.r - d * d)

type Step = { p :: V.Vector, d :: Number }

type Options = { useHinting :: Boolean, randomFactor :: Number }

trace :: Options -> Int -> Ray -> Source -> (List Segment) -> Effect (Maybe (List Step))
trace { useHinting, randomFactor } max start source segments = _trace max start false ({ p: start.o, d: 0.0 } : Nil)
  where
  _trace 0 _ _ _ = pure Nothing

  _trace n ray doHint acc = do
    hint <- if doHint then hintStep ray else pure Nothing
    case hint of
      Just s -> pure $ Just (s : acc)
      Nothing -> do
        segmentTest <- (performTrace ray)
        sourceTest <- pure $ (intersectSource ray source)
        case (Tuple segmentTest sourceTest) of
          Tuple Nothing Nothing -> pure Nothing
          Tuple Nothing (Just d) -> pure $ Just ({ p: ray.o + (V.scale d ray.r), d: d } : acc)
          Tuple (Just newRay) Nothing -> _trace (n - 1) newRay useHinting ({ p: newRay.o, d: (V.abs (newRay.o - ray.o)) } : acc)
          Tuple (Just newRay) (Just d) ->
            if d <= (V.abs (newRay.o - ray.o)) then
              pure $ Just ({ p: ray.o + (V.scale d ray.r), d: d } : acc)
            else
              _trace (n - 1) newRay useHinting ({ p: newRay.o, d: (V.abs (newRay.o - ray.o)) } : acc)

  hintStep ray = do
    patte <- random
    hit <- performTrace $ { o: ray.o, r: V.norm $ V.rotate u (patte * 0.2) }
    case hit of
      Nothing -> pure $ Just { p: source.o, d: d }
      Just { o } ->
        if d <= (V.abs (o - ray.o)) then
          pure $ Just { p: source.o, d: d }
        else
          pure $ Nothing
    where
    u = source.o - ray.o

    d = V.abs u

  performTrace ray = do
    cock <- random
    let
      hit = findIntersection ray segments
    case hit of
      Nothing -> pure Nothing
      Just { seg, t } ->
        let
          point = ray.o + (V.scale t ray.r)

          plane = (seg.p1 - seg.p0)

          refl = V.reflect ray.r (V.normal plane)

          skewed = V.rotate refl ((coolRandomAngle plane refl cock) * randomFactor)
        in
          pure $ Just { o: point, r: skewed }

coolRandomAngle :: V.Vector -> V.Vector -> Number -> Number
coolRandomAngle plane vec x = phi * x
  where
  phi = (V.dot plane vec) / (V.abs plane * V.abs vec)

sourceTag :: String
sourceTag = "GRAPH_SOURCE"

makeGraph :: List Step -> El.Node
makeGraph steps = El.mul (El.const "______" totalAttenuation) $ El.sdelay totalDelay (El.tapIn sourceTag)
  where
  totalDelay = foldl (\a -> \s -> a + (s.d / speedOfSound)) 0.0 steps

  totalAttenuation = (pow 0.95 (pow (toNumber $ (length steps - 1)) 1.5))
  -- totalAttenuation = 1.0

  speedOfSound = 343.0

-- makeGraph :: List Step -> El.Node
-- makeGraph steps = foldl (makeNode) (El.tapIn sourceTag) steps
--   where
--   makeNode n { d } = El.mul (El.const "______" 0.9) $ El.sdelay (d / speedOfSound) n
-- 
--   speedOfSound = 343.0
renderGraph :: List (List Step) -> Number -> El.Node
renderGraph paths attenuation = combineGraphs (makeGraph <$> paths)
  where
  combineGraphs subGraph = El.mix ((El.mul (El.const "___" attenuation)) <$> subGraph)
