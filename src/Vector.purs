module Vector
  ( module Vector.Impl
  , (+)
  , (-)
  , (*)
  ) where

import Vector.Impl

infixl 6 add as +

infixl 6 sub as -

infixl 7 scale as *
