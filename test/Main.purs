module Test.Main where

import Prelude
import Data.Maybe (Maybe(..))
import Data.Number (sqrt)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Space2D (intersect)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Console (write)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)
import Vector as V

main :: Effect Unit
main =
  launchAff_
    $ runSpec [ consoleReporter ] do
        describe "Space2D" do
          describe "intersect" do
            -- it "simple line" do
            --   let
            --     r1 = { o: V.fromFoldable [ 0.0, 0.0 ], r: V.norm $ V.fromFoldable [ 1.0, 0.0 ] }
            --   let
            --     r2 = { o: V.fromFoldable [ 1.0, 0.0 ], r: V.fromFoldable [ 0.0, 1.0 ] }
            --   shouldEqual (intersect r1 r2) (Just { x: 1.0, y: 0.0 })
            -- it "simple line further away" do
            --   let
            --     r1 = { o: V.fromFoldable [ 0.0, 0.0 ], r: V.norm $ V.fromFoldable [ 1.0, 0.0 ] }
            --   let
            --     r2 = { o: V.fromFoldable [ 2.0, 0.0 ], r: V.fromFoldable [ 0.0, 1.0 ] }
            --   shouldEqual (intersect r1 r2) (Just { x: 2.0, y: 0.0 })
            it "Diagonal at unit away" do
              let
                r1 = { o: V.fromFoldable [ 0.0, 0.0 ], r: V.norm $ V.fromFoldable [ 1.0, 1.0 ] }
              let
                r2 = { o: V.fromFoldable [ 1.0, 0.0 ], r: V.fromFoldable [ 0.0, 1.0 ] }
              shouldEqual (intersect r1 r2) (Just { x: sqrt 2.0, y: 1.0 })

-- it "exists" do
--   log $ show s.ol
--   pure unit
--           describe "Math" do
--             it "works"
--               $ quickCheck \n -> (n * 2 / 2) === n
--             it "works again"
--               $ quickCheck \n -> ((n + 1) * 2) /== n
--           describe "Attributes" do
--             it "awesome" do
--               let
--                 isAwesome = true
--               isAwesome `shouldEqual` true
--             pending "feature complete"
--           describe "Features" do
--             it "runs in NodeJS" $ pure unit
--             it "runs in the browser" $ pure unit
--             it "supports streaming reporters" $ pure unit
--             it "supports async specs" do
--               res <- delay (Milliseconds 100.0) $> "Alligator"
--               res `shouldEqual` "Alligator"
--             it "is PureScript 0.12.x compatible" $ pure unit
