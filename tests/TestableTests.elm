module TestableTests (..) where

import ElmTest exposing (..)
import Testable.TestContext as TestContext
import Testable.Effects as Effects


type CounterAction
  = Inc
  | Dec


counterComponent : TestContext.Component CounterAction Int
counterComponent =
  { init = ( 0, Effects.none )
  , update =
      \action model ->
        case action of
          Inc ->
            ( model + 1, Effects.none )

          Dec ->
            ( model - 1, Effects.none )
  }


type LoadingAction
  = NewData String


loadingComponent : TestContext.Component LoadingAction (Maybe String)
loadingComponent =
  { init =
      ( Nothing
      , Effects.http "https://example.com/"
          |> Effects.map NewData
      )
  , update =
      \action model ->
        case action of
          NewData data ->
            ( Just data, Effects.none )
  }


loadingComponentWithMultipleEffects : TestContext.Component LoadingAction (Maybe String)
loadingComponentWithMultipleEffects =
  let
    multipleEffects =
      List.map
        (Effects.map NewData)
        [ Effects.http "https://example.com/"
        , Effects.http "https://secondexample.com/"
        ]
  in
    { init =
        ( Nothing
        , Effects.batch multipleEffects
        )
    , update =
        \action model ->
          case action of
            NewData data ->
              ( Just data, Effects.none )
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
    , loadingComponent
        |> TestContext.startForTest
        |> TestContext.stubHttpRequest "https://example.com/" "myData-1"
        |> TestContext.currentModel
        |> assertEqual (Ok (Just "myData-1"))
        |> test "records initial effects"
    , loadingComponent
        |> TestContext.startForTest
        |> TestContext.stubHttpRequest "https://badwebsite.com" "_"
        |> TestContext.currentModel
        |> assertEqual (Err [ "No pending HTTP request: https://badwebsite.com" ])
        |> test "stubbing an unmatched effect should produce an error"
    , loadingComponent
        |> TestContext.startForTest
        |> TestContext.stubHttpRequest "https://example.com/" "myData-1"
        |> TestContext.stubHttpRequest "https://example.com/" "myData-2"
        |> TestContext.currentModel
        |> assertEqual (Err [ "No pending HTTP request: https://example.com/" ])
        |> test "effects should be removed after they are run"
    , loadingComponentWithMultipleEffects
        |> TestContext.startForTest
        |> TestContext.stubHttpRequest "https://example.com/" "myData-1"
        |> TestContext.stubHttpRequest "https://secondexample.com/" "myData-2"
        |> TestContext.currentModel
        |> assertEqual (Ok (Just "myData-2"))
        |> test "multiple initial effects should be resolvable"
    ]
