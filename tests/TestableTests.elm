module TestableTests (..) where

import ElmTest exposing (..)
import Json.Decode as Decode
import Testable.TestContext as TestContext
import Testable.Effects as Effects
import Testable.Http as Http


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
      , Http.getString "https://example.com/"
          |> Effects.map NewData
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
        |> TestContext.assertHttpRequest
            (Http.getRequest "https://example.com/")
        |> test "records initial effects"
    , loadingComponent
        |> TestContext.startForTest
        |> TestContext.resolveHttpRequest
            (Http.getRequest "https://example.com/")
            "myData-1"
        |> TestContext.currentModel
        |> assertEqual (Ok <| Just "myData-1")
        |> test "records initial effects"
    , loadingComponent
        |> TestContext.startForTest
        |> TestContext.resolveHttpRequest
            (Http.getRequest "https://badwebsite.com/")
            "_"
        |> TestContext.currentModel
        |> assertEqual (Err [ "No pending HTTP request: { verb = \"GET\", headers = [], url = \"https://badwebsite.com/\", body = Empty }" ])
        |> test "stubbing an unmatched effect should produce an error"
    , loadingComponent
        |> TestContext.startForTest
        |> TestContext.resolveHttpRequest
            (Http.getRequest "https://example.com/")
            "myData-1"
        |> TestContext.resolveHttpRequest
            (Http.getRequest "https://example.com/")
            "myData-2"
        |> TestContext.currentModel
        |> assertEqual (Err [ "No pending HTTP request: { verb = \"GET\", headers = [], url = \"https://example.com/\", body = Empty }" ])
        |> test "effects should be removed after they are run"
    , { init =
          ( Nothing
          , Effects.batch
              [ Http.getString "https://example.com/"
              , Http.getString "https://secondexample.com/"
              ]
          )
      , update = \data model -> ( Just data, Effects.none )
      }
        |> TestContext.startForTest
        |> TestContext.resolveHttpRequest
            (Http.getRequest "https://example.com/")
            "myData-1"
        |> TestContext.resolveHttpRequest
            (Http.getRequest "https://secondexample.com/")
            "myData-2"
        |> TestContext.currentModel
        |> assertEqual (Ok <| Just "myData-2")
        |> test "multiple initial effects should be resolvable"
    , { init =
          ( Ok 0
          , Http.post Decode.float "https://a" (Http.string "requestBody")
          )
      , update = \value model -> ( value, Effects.none )
      }
        |> TestContext.startForTest
        |> TestContext.resolveHttpRequest
            { verb = "POST"
            , headers = []
            , url = "https://a"
            , body = Http.string "requestBody"
            }
            "99.1"
        |> TestContext.currentModel
        |> assertEqual (Ok <| Ok 99.1)
        |> test "Http.post effect"
    ]
