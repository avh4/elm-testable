module TestableTests (..) where

import ElmTest exposing (..)
import Testable.TestContext as TestContext


type CounterAction
  = Inc
  | Dec


counterComponent : TestContext.Component CounterAction Int
counterComponent =
  { init = \effects -> ( 0, effects.none )
  , update =
      \effects action model ->
        case action of
          Inc ->
            ( model + 1, effects.none )

          Dec ->
            ( model - 1, effects.none )
  }


loadingComponent : TestContext.Component () (Maybe String)
loadingComponent =
  { init = \effects -> ( Nothing, effects.http.get "https://example.com/" )
  , update = \effects action model -> ( model, effects.none )
  }


all : Test
all =
  suite
    "Testable"
    [ counterComponent
        |> TestContext.startForTest
        |> TestContext.currentModel
        |> assertEqual (Ok 0)
        |> test "initialized with initial model"
    , counterComponent
        |> TestContext.startForTest
        |> TestContext.update Inc
        |> TestContext.update Inc
        |> TestContext.currentModel
        |> assertEqual (Ok 2)
        |> test "sending an action"
    , loadingComponent
        |> TestContext.startForTest
        |> TestContext.assertHttpRequest "https://example.com/"
        |> test "records initial effects"
    ]
