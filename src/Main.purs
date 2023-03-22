module Main where

import Prelude

import Data.Foldable (foldl)
import Data.Int (toNumber)
import Data.List (List, length)
import Data.Traversable (class Traversable)
import Data.Unfoldable (class Unfoldable, replicateA)
import Effect (Effect)
import Effect.Class (class MonadEffect)
import El as El
import Halogen as H
import Halogen.Aff (awaitBody, runHalogenAff)
import Halogen.HTML as HH
import Halogen.HTML.Events as HV
import Halogen.VDom.Driver (runUI)
import Materials (Material(..), impedance)
import Space (testWorld1, traverse)

main :: Effect Unit
main =
  runHalogenAff do
    body <- awaitBody
    core <- H.liftEffect El.createCore
    _ <- H.liftEffect $ traverse testWorld1
    runUI component core body

type State
  = { core :: El.Core }

data Action
  = Nothing

component :: forall query output m. MonadEffect m => H.Component query El.Core output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }

initialState :: El.Core -> State
initialState core = { core: core }

render :: forall m. State -> H.ComponentHTML Action () m
render _ = do
  HH.div_
    $ [ HH.button [ HV.onClick \_ -> Nothing ] [ HH.text "kuken" ]
      , HH.div_ anus
      ]

balle :: forall w15 i16. Material -> HH.HTML w15 i16
balle x = HH.div_ [ HH.text $ show $ impedance x ]

anus :: forall t95 t96. Array (HH.HTML t95 t96)
anus = balle <$> [ Air, Fabric, Wood, Concrete ]

mix :: List El.Node -> El.Node
mix l =
  let
    damp = 1.0 / (toNumber $ length l)
  in
    El.mul damp $ foldl (El.add) (El.const "_" 0.0) l


keso :: forall f22. Unfoldable f22 => Traversable f22 => Effect (f22 El.Node)
keso = replicateA 1000 (traverse testWorld1)

handleAction :: forall output m. MonadEffect m => Action -> H.HalogenM State Action () output m Unit
handleAction = case _ of
  Nothing -> do
    thing <- H.liftEffect keso
    core <- H.gets _.core
    core2 <- H.liftEffect $ El.renderMono core (mix thing)
    H.modify_ \state -> state {core = core2}

  --   Kuken _ -> do
  --   core <- H.gets _.core
  --   core2 <- H.liftEffect $ El.renderMono core $ M.renderRack rack
  --   H.modify_ \state -> state {core = core2}
  -- _ -> H.modify_ \state -> state
