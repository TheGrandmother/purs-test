module El
  ( Core
  , Ctx
  , createCore
  , createCtx
  , onCoreLoad
  , flerp
  , play
  ) where

import Data.Unit (Unit)
import Effect (Effect)

type Core
  = {}

type Ctx
  = {}

foreign import createCore :: Core

foreign import createCtx :: Ctx

foreign import flerp :: Core -> Unit

foreign import onCoreLoad :: Core -> (Core -> Unit) -> Effect Unit

foreign import play :: Core -> Ctx -> Effect Unit
