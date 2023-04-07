module Space where

import Prelude
import Data.Foldable (class Foldable, foldl, foldr)
import Data.Int (toNumber)
import Data.List (List(..), filter, fromFoldable, head, length, reverse, (:))
import Data.Number (abs, e, pow)
import Data.Number.Format (precision, toStringWith)
import Data.Traversable (class Traversable)
import Data.Unfoldable (class Unfoldable, replicateA)
import Effect (Effect)
import Effect.Console (log)
import Effect.Random (random)
import El as El
import Materials (Material(..), impedance, speedOfSound)

data Segment
  = Medium Material Number
  | Source El.Node
  | Mic

instance showMaterial :: Show Segment where
  show (Medium mat d) = (show mat) <> (show d)
  show (Source _) = "source"
  show Mic = "Mic"

data World
  = Array Segment

tc :: String -> Number -> El.Node
tc t v = El.const t v

pwmTrain :: Number -> Number -> El.Node
pwmTrain freq duty = El.sm $ El.le (El.ramp $ tc "f" freq) $ tc "d" duty

pulseGen :: Number -> Number -> Number -> El.Node
pulseGen pulseFreq duty freq = El.mul (El.cycle $ El.const "os_f" freq) (pwmTrain pulseFreq duty)

testWorld1 :: List Segment
testWorld1 =
  fromFoldable
    [ Mic
    , Medium Air 10.0
    , Medium Wood 0.005
    , Medium Air 10.0
    , Medium Wood 0.01
    , Medium Air 40.0
    , Medium Wood 0.01
    , Medium Air 10.0
    , Source (El.tapIn "GRAPH_SOURCE")
    -- , Source (sample "test.wav" (pwmTrain 0.15 0.1) 1.0)
    ]

data Interaction
  = Reflection Number Number Number -- Delay Attenuation Freq
  | Absorbtion Number Number Number

instance showInteraction :: Show Interaction where
  show (Absorbtion d att f) = "Absorb " <> (fmt (d * 1000.0)) <> "ms " <> (fmt att) <> "x " <> (fmt f) <> "hz \n"
  show (Reflection d att f) = "Reflect " <> (fmt (d * 1000.0)) <> "ms " <> (fmt att) <> "x " <> (fmt f) <> "hz \n"

fmt :: Number -> String
fmt x = toStringWith (precision 3) x

getTotalAttenuation :: List Interaction -> Number
getTotalAttenuation Nil = 0.0

getTotalAttenuation trace = foldr (\t -> \n -> (getAtt t * n)) 1.0 trace
  where
  getAtt (Absorbtion _ att _) = abs att

  getAtt (Reflection _ att _) = abs att

getTotalDelay :: List Interaction -> Number
getTotalDelay Nil = 0.0

getTotalDelay trace = foldr (\t -> \n -> (getDelay t + n)) 0.0 trace
  where
  getDelay (Absorbtion d _ _) = d

  getDelay (Reflection d _ _) = d

sourceTag :: String
sourceTag = "GRAPH_SOURCE"

combine :: Path -> El.Node
combine l = _combine $ reverse l
  where
  _combine Nil = (El.tapIn sourceTag)

  _combine ((Absorbtion delay att fc) : crap) = El.sdelay delay $ El.mul att $ El.lowpass fc 1.0 $ combine crap

  _combine ((Reflection delay att fc) : crap) = El.sdelay delay $ El.mul att $ El.lowpass fc 1.0 $ combine crap

sum :: forall a. Foldable a => a Int -> Int
sum a = foldl add 0 a

produceGraph :: List Segment -> Int -> Effect El.Node
produceGraph world count = do
  samples <- _samples
  -- log $ (show $ length <$> samples)
  log $ (show $ length samples)
  completeTraces <- pure $ filter (\s -> getTotalAttenuation s > 0.001) samples
  log $ (show $ head <$> completeTraces)
  log $ (show $ sum $ length <$> completeTraces)
  graphs <- pure $ combine <$> completeTraces
  log $ (show $ length graphs)
  pure $ El.mix graphs
  where
  _samples :: Effect (List Path)
  _samples = replicateA count (traverse world)

test :: Effect Unit
test = do
  otto <- traverse testWorld1
  log (show otto)
  log (show $ getTotalAttenuation otto)
  bob <- x
  goodBois <- pure $ filter (\xx -> getTotalAttenuation xx > 0.0001) bob
  log $ (show $ getTotalAttenuation <$> goodBois)
  log $ (show $ length <$> goodBois)
  log $ (show $ getTotalDelay <$> goodBois)
  log $ (show ((toNumber (length goodBois)) / (toNumber count)))
  where
  count = 200

  x :: Applicative Effect => Unfoldable List => Traversable List => Effect (List Path)
  x = replicateA count (traverse testWorld1)

type Path
  = List Interaction

traverse :: List Segment -> Effect Path
traverse l = _traverse maxBounces Nil l Nil
  where
  maxBounces = 500

  _traverse :: Int -> List Segment -> List Segment -> (List Interaction) -> Effect (List Interaction)
  _traverse x _ _ trace
    | x == 0 = pure trace

  _traverse n Nil (Mic : ((Medium m dx) : ahead)) trace = _traverse (n - 1) ((Medium m dx) : Mic : Nil) ahead (makeAbsorbtion m dx : trace)

  _traverse n ((Medium m0 dx0) : behind) ((Medium m1 dx1) : ahead) trace = do
    pick <- random
    if pick < (abs rc) then
      _traverse (n - 1) ((Medium m0 dx0) : (Medium m1 dx1) : ahead) (behind) (makeReflection m0 dx0 : trace)
    else
      _traverse (n - 1) ((Medium m1 dx1) : (Medium m0 dx0) : behind) ahead (makeAbsorbtion m1 dx1 : trace)
    where
    rc = (z1 - z0) / (z1 + z0)
      where
      z1 = impedance m1 * dx1

      z0 = impedance m0 * dx0

  _traverse _ ((Medium m x) : _) (Source _ : Nil) trace = do
    pure (makeAbsorbtion m x : trace)

  _traverse _ _ _ _ = pure Nil

makeReflection :: Material -> Number -> Interaction
makeReflection m x = (Reflection (x / speedOfSound m) (-1.0 * (attenuate x (impedance m))) (cutoffFreq x (impedance m)))

makeAbsorbtion :: Material -> Number -> Interaction
makeAbsorbtion m x = (Absorbtion (x / speedOfSound m) (attenuate x (impedance m)) (cutoffFreq x (impedance m)))

cutoffFreq :: Number -> Number -> Number
cutoffFreq x z = (20000.0 * (1.0 - ((pow e) $ (-1.0 / (x * z * z * 0.001)))))

attenuate :: Number -> Number -> Number
attenuate dx z = (pow e) $ -1.0 * dx * z * 0.0001
