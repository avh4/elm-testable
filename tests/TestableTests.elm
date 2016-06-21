module TestableTests exposing (..)

import ElmTest exposing (..)
import Json.Decode as Decode
import Testable.TestContext as TestContext
import Testable.Cmd
import Testable.Http as Http
import Http as ElmHttp
import Testable.Task as Task
import Time


type CounterMsg
    = Inc
    | Dec


counterComponent : TestContext.Component CounterMsg Int
counterComponent =
    { init = ( 0, Testable.Cmd.none )
    , update =
        \msg model ->
            case msg of
                Inc ->
                    ( model + 1, Testable.Cmd.none )

                Dec ->
                    ( model - 1, Testable.Cmd.none )
    }


type LoadingMsg
    = NewData (Result Http.Error String)


loadingComponent : TestContext.Component LoadingMsg (Maybe String)
loadingComponent =
    { init =
        ( Nothing
        , Http.getString "https://example.com/"
            |> Task.perform Err Ok
            |> Testable.Cmd.map NewData
        )
    , update =
        \msg model ->
            case msg of
                NewData (Ok data) ->
                    ( Just data, Testable.Cmd.none )

                NewData (Err _) ->
                    ( model, Testable.Cmd.none )
    }


type RawLoadingMsg
    = RawNewData (Result Http.RawError String)


componentWithSendSettings : Http.Settings
componentWithSendSettings =
    { timeout = 500
    , onStart = Just <| Task.succeed ()
    , onProgress = Nothing
    , desiredResponseType = Just "text/plain"
    , withCredentials = True
    }


loadingComponentWithSend : TestContext.Component RawLoadingMsg (Maybe String)
loadingComponentWithSend =
    let
        initRequest =
            { url = "https://example.com/"
            , verb = "GET"
            , headers = []
            , body = Http.empty
            }

        parseResponseValue response =
            case response.value of
                ElmHttp.Text str ->
                    str

                _ ->
                    "Unsupported body type"
    in
        { init =
            ( Nothing
            , Http.send componentWithSendSettings initRequest
                |> Task.perform Err Ok
                |> Testable.Cmd.map ((Result.map parseResponseValue) >> RawNewData)
            )
        , update =
            \msg model ->
                case msg of
                    RawNewData (Ok data) ->
                        ( Just data, Testable.Cmd.none )

                    RawNewData (Err _) ->
                        ( model, Testable.Cmd.none )
        }


all : Test
all =
    suite "Testable"
        [ counterComponent
            |> TestContext.startForTest
            |> TestContext.assertCurrentModel 0
            |> test "initialized with initial model"
        , counterComponent
            |> TestContext.startForTest
            |> TestContext.update Inc
            |> TestContext.update Inc
            |> TestContext.assertCurrentModel 2
            |> test "sending an msg"
        , loadingComponent
            |> TestContext.startForTest
            |> TestContext.assertHttpRequest (Http.getRequest "https://example.com/")
            |> test "records initial effects"
        , loadingComponent
            |> TestContext.startForTest
            |> TestContext.resolveHttpRequest (Http.getRequest "https://example.com/")
                (Http.ok "myData-1")
            |> TestContext.assertCurrentModel (Just "myData-1")
            |> test "records initial effects"
        , loadingComponent
            |> TestContext.startForTest
            |> TestContext.resolveHttpRequest (Http.getRequest "https://badwebsite.com/")
                (Http.ok "_")
            |> TestContext.currentModel
            |> assertEqual (Err [ "No pending HTTP request: { verb = \"GET\", headers = [], url = \"https://badwebsite.com/\", body = Empty }" ])
            |> test "stubbing an unmatched effect should produce an error"
        , loadingComponent
            |> TestContext.startForTest
            |> TestContext.resolveHttpRequest (Http.getRequest "https://example.com/")
                (Http.ok "myData-1")
            |> TestContext.resolveHttpRequest (Http.getRequest "https://example.com/")
                (Http.ok "myData-2")
            |> TestContext.currentModel
            |> assertEqual (Err [ "No pending HTTP request: { verb = \"GET\", headers = [], url = \"https://example.com/\", body = Empty }" ])
            |> test "effects should be removed after they are run"
        , loadingComponentWithSend
            |> TestContext.startForTest
            |> TestContext.assertHttpRequestWithSettings componentWithSendSettings
                (Http.getRequest "https://example.com/")
            |> test "records initial effects successfully when sending an arbitrary request"
        , loadingComponentWithSend
            |> TestContext.startForTest
            |> TestContext.resolveHttpRequestWithSettings componentWithSendSettings
                (Http.getRequest "https://example.com/")
                (Http.ok "myData-1")
            |> TestContext.assertCurrentModel (Just "myData-1")
            |> test "updates with successful response when sending an arbitrary request"
        , { init =
                ( Nothing
                , Testable.Cmd.batch
                    [ Task.perform Err Ok <| Http.getString "https://example.com/"
                    , Task.perform Err Ok <| Http.getString "https://secondexample.com/"
                    ]
                )
          , update = \data model -> ( Just data, Testable.Cmd.none )
          }
            |> TestContext.startForTest
            |> TestContext.resolveHttpRequest (Http.getRequest "https://example.com/")
                (Http.ok "myData-1")
            |> TestContext.resolveHttpRequest (Http.getRequest "https://secondexample.com/")
                (Http.ok "myData-2")
            |> TestContext.assertCurrentModel (Just <| Ok "myData-2")
            |> test "multiple initial effects should be resolvable"
        , { init =
                ( Ok 0
                , Http.post Decode.float "https://a" (Http.string "requestBody")
                    |> Task.perform Err Ok
                )
          , update = \value model -> ( value, Testable.Cmd.none )
          }
            |> TestContext.startForTest
            |> TestContext.resolveHttpRequest
                { verb = "POST"
                , headers = []
                , url = "https://a"
                , body = Http.string "requestBody"
                }
                (Http.ok "99.1")
            |> TestContext.assertCurrentModel (Ok 99.1)
            |> test "Http.post effect"
        , { init = ( "waiting", Task.succeed "ready" |> Task.perform identity identity )
          , update = \value model -> ( value, Testable.Cmd.none )
          }
            |> TestContext.startForTest
            |> TestContext.assertCurrentModel "ready"
            |> test "Task.succeed"
        , { init = ( Ok "waiting", Task.fail "failed" |> Task.perform Err Ok )
          , update = \value model -> ( value, Testable.Cmd.none )
          }
            |> TestContext.startForTest
            |> TestContext.assertCurrentModel (Err "failed")
            |> test "Task.fail"
        , { init = ( 0, Task.succeed 100 |> Task.andThen ((+) 1 >> Task.succeed) |> Task.perform identity identity )
          , update = \value model -> ( value, Testable.Cmd.none )
          }
            |> TestContext.startForTest
            |> TestContext.assertCurrentModel 101
            |> test "Task.andThen"
        , { init =
                ( "waiting"
                , Task.sleep (5 * Time.second)
                    |> Task.andThen (\_ -> Task.succeed "5 seconds passed")
                    |> Task.perform identity identity
                )
          , update = \value mode -> ( value, Testable.Cmd.none )
          }
            |> TestContext.startForTest
            |> TestContext.advanceTime (4 * Time.second)
            |> TestContext.assertCurrentModel "waiting"
            |> test "Task.sleep"
        , { init =
                ( "waiting"
                , Task.sleep (5 * Time.second)
                    |> Task.andThen (\_ -> Task.succeed "5 seconds passed")
                    |> Task.perform identity identity
                )
          , update = \value mode -> ( value, Testable.Cmd.none )
          }
            |> TestContext.startForTest
            |> TestContext.advanceTime (5 * Time.second)
            |> TestContext.assertCurrentModel "5 seconds passed"
            |> test "Task.sleep"
        ]
