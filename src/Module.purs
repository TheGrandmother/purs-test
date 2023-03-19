module Module (quiet, RackModule(..), Id, renderRack, Parameter(..), moduleInfo, ModuleInfo, getControls, setValue) where

import Prelude

import Data.Foldable (class Foldable, foldl)
import Data.Map (Map)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import El as El
import Foreign.Object (lookup)

data Parameter = Smooth String String Number Number Number

quiet :: El.Node
quiet = El.const "_quiet_" 0.0

paramToConst :: Parameter -> String -> El.Node
paramToConst (Smooth name _ _ _ value) moduleId = El.const (moduleId <> ":" <> name) value

setValue :: Parameter -> Maybe Number -> Parameter
setValue (Smooth a b c d _) (Just new_value) = Smooth a b c d new_value
setValue p _ = p

--updateControl :: Module -> String -> Parameter -> Module
--updateControl 


-- data Module = Module (Array Parameter) (Array El.Node) (Array El.Node) Int

type Id = String
type Printable = (forall a. Show a => a)

newtype Showable = Showable (forall r. (forall a. Show a => a -> r) -> r)

instance showShowable :: Show Showable where
  show (Showable a) = a show

data RackModule
  = Clock String { freq :: Parameter }
  | Output String { volume :: Parameter } { signalIn :: El.Node }
  | BasicOsc String { tune :: Parameter } { freqIn :: El.Node }
  | Vca String { controlIn :: El.Node, sourceIn :: El.Node }

type ModuleSpec = {name :: String, id :: String, controls :: Map String Parameter, inputs :: Map String El.Node, outputs :: Array String}
type RackModule = {spec :: ModuleSpec, renderFunction :: ModuleSpec -> El.Node}

renderModule :: RackModule -> El.Node
renderModule (Clock id { freq }) = El.tapOut (id <> ":out") $ El.train $ paramToConst freq id
renderModule (Output id { volume } { signalIn }) = El.tapOut "main_out" $ El.mul (signalIn) (paramToConst volume id)
renderModule (BasicOsc id { tune } { freqIn }) =
  let
    f = El.add (paramToConst tune id) freqIn
  in
    El.tapOut (id <> ":out") $ El.blepsquare $ cvToHz f 440.0
renderModule (Vca id { controlIn, sourceIn }) = El.tapOut (id <> ":out") $ El.mul controlIn sourceIn

type ModuleInfo = { name :: String, id :: String, inputs :: Array { source :: String, destination :: String }, outputs :: Array String }

moduleInfo :: RackModule -> ModuleInfo
moduleInfo (Clock id _) = { name: "Clock", id: id, inputs: [], outputs: [ "out" ] }
moduleInfo (Output id _ { signalIn }) = { name: "Output", id: id, inputs: [ { source: getName signalIn, destination: "signalIn" } ], outputs: [] }
moduleInfo (BasicOsc id _ { freqIn }) = { name: "VCO", id: id, inputs: [ { source: getName freqIn, destination: "freqIn" } ], outputs: [ "out" ] }
moduleInfo (Vca id { controlIn, sourceIn }) = { name: "Vca", id: id, inputs: [ { source: getName controlIn, destination: "controlIn" }, { source: getName sourceIn, destination: "sourceIn" } ], outputs: [ "out" ] }

getControls :: RackModule -> Array (Tuple String Parameter)
getControls (Clock _ { freq }) = [ Tuple "freq" freq ]
getControls (Output _ { volume } _) = [ Tuple "volume" volume ]
getControls (BasicOsc _ { tune } _) = [ Tuple "tune" tune ]
getControls _ = []


getName :: El.Node -> String
getName i = case lookup "name" (El.getProps i) of
  Nothing -> ""
  Just n -> n

class Input :: forall k. k -> Constraint
class Input a

instance fieldNode :: Input Number
instance inputNode :: Input El.Node

cvToHz :: forall x y. Input x => x -> Input y => y -> El.Node
cvToHz cv base = El.mul (El.pow 2 cv) base

renderRack :: forall f. Functor f => Foldable f => f RackModule -> El.Node
renderRack modules = El.add (El.tapIn "main_out") $ El.mul (quiet) $ foldl (El.add) (quiet) (renderModule <$> modules)

