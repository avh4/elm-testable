port module TestableTests exposing (..)

import Expect
import Json.Decode as Decode
import Testable.TestContext as TestContext
import Testable.Cmd
import Testable.Http as Http exposing (defaultSettings)
import Testable.Html exposing (div, input, text)
import Test exposing (..)
import Testable.Html.Selector exposing (..)
import Testable.Task as Task
import Testable.Process as Process
import Platform.Cmd
import Time
import Expect


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
    , view = \model -> text ""
    }


type LoadingMsg
    = NewData (Result Http.Error String)


loadingComponent : TestContext.Component LoadingMsg (Maybe String)
loadingComponent =
    { init =
        ( Nothing
        , Http.getString "https://example.com/"
            |> Http.toTask
            |> Task.attempt identity
            |> Testable.Cmd.map NewData
        )
    , update =
        \msg model ->
            case msg of
                NewData (Ok data) ->
                    ( Just data, Testable.Cmd.none )

                NewData (Err _) ->
                    ( model, Testable.Cmd.none )
    , view = \model -> text ""
    }


port outgoingPort : String -> Platform.Cmd.Cmd msg


all : Test
all =
    describe "Testable"
        [ test "initialized with initial model" <|
            \() ->
                counterComponent
                    |> TestContext.startForTest
                    |> TestContext.assertCurrentModel 0
        , test "sending an msg" <|
            \() ->
                counterComponent
                    |> TestContext.startForTest
                    |> TestContext.update Inc
                    |> TestContext.update Inc
                    |> TestContext.assertCurrentModel 2
        , test "records initial effects" <|
            \() ->
                loadingComponent
                    |> TestContext.startForTest
                    |> TestContext.assertHttpRequest (Http.getRequest "https://example.com/")
        , test "records initial effects" <|
            \() ->
                loadingComponent
                    |> TestContext.startForTest
                    |> TestContext.resolveHttpRequest (Http.getRequest "https://example.com/")
                        (Http.ok "myData-1")
                    |> TestContext.assertCurrentModel (Just "myData-1")
        , test "stubbing an unmatched effect should produce an error" <|
            \() ->
                loadingComponent
                    |> TestContext.startForTest
                    |> TestContext.resolveHttpRequest (Http.getRequest "https://badwebsite.com/")
                        (Http.ok "_")
                    |> TestContext.currentModel
                    |> Expect.equal (Err [ "No pending HTTP request: { method = \"GET\", headers = [], body = EmptyBody, timeout = Nothing, url = \"https://badwebsite.com/\", withCredentials = False }" ])
        , test "effects should be removed after they are run" <|
            \() ->
                loadingComponent
                    |> TestContext.startForTest
                    |> TestContext.resolveHttpRequest (Http.getRequest "https://example.com/")
                        (Http.ok "myData-1")
                    |> TestContext.resolveHttpRequest (Http.getRequest "https://example.com/")
                        (Http.ok "myData-2")
                    |> TestContext.currentModel
                    |> Expect.equal (Err [ "No pending HTTP request: { method = \"GET\", headers = [], body = EmptyBody, timeout = Nothing, url = \"https://example.com/\", withCredentials = False }" ])
        , test "multiple initial effects should be resolvable" <|
            \() ->
                { init =
                    ( Nothing
                    , Testable.Cmd.batch
                        [ Task.attempt identity <| Http.toTask <| Http.getString "https://example.com/"
                        , Task.attempt identity <| Http.toTask <| Http.getString "https://secondexample.com/"
                        ]
                    )
                , update = \data model -> ( Just data, Testable.Cmd.none )
                , view = \model -> text ""
                }
                    |> TestContext.startForTest
                    |> TestContext.resolveHttpRequest (Http.getRequest "https://example.com/")
                        (Http.ok "myData-1")
                    |> TestContext.resolveHttpRequest (Http.getRequest "https://secondexample.com/")
                        (Http.ok "myData-2")
                    |> TestContext.assertCurrentModel (Just <| Ok "myData-2")
        , test "Http.post effect" <|
            \() ->
                { init =
                    ( Ok 0
                    , Http.post "https://a" (Http.stringBody "text/plain" "requestBody") Decode.float
                        |> Http.toTask
                        |> Task.attempt identity
                    )
                , update = \value model -> ( value, Testable.Cmd.none )
                , view = \model -> text ""
                }
                    |> TestContext.startForTest
                    |> TestContext.resolveHttpRequest
                        { defaultSettings
                            | url = "https://a"
                            , method = "POST"
                            , body = (Http.stringBody "text/plain" "requestBody")
                        }
                        (Http.ok "99.1")
                    |> TestContext.assertCurrentModel (Ok 99.1)
        , test "Task.succeed" <|
            \() ->
                { init = ( "waiting", Task.succeed "ready" |> Task.perform identity )
                , update = \value model -> ( value, Testable.Cmd.none )
                , view = \model -> text ""
                }
                    |> TestContext.startForTest
                    |> TestContext.assertCurrentModel "ready"
        , test "Task.fail" <|
            \() ->
                { init = ( Ok "waiting", Task.fail "failed" |> Task.attempt identity )
                , update = \value model -> ( value, Testable.Cmd.none )
                , view = \model -> text ""
                }
                    |> TestContext.startForTest
                    |> TestContext.assertCurrentModel (Err "failed")
        , test "Task.andThen" <|
            \() ->
                { init = ( 0, Task.succeed 100 |> Task.andThen ((+) 1 >> Task.succeed) |> Task.perform identity )
                , update = \value model -> ( value, Testable.Cmd.none )
                , view = \model -> text ""
                }
                    |> TestContext.startForTest
                    |> TestContext.assertCurrentModel 101
        , test "Process.sleep" <|
            \() ->
                { init =
                    ( "waiting"
                    , Process.sleep (5 * Time.second)
                        |> Task.andThen (\_ -> Task.succeed "5 seconds passed")
                        |> Task.perform identity
                    )
                , update = \value mode -> ( value, Testable.Cmd.none )
                , view = \model -> text ""
                }
                    |> TestContext.startForTest
                    |> TestContext.advanceTime (4 * Time.second)
                    |> TestContext.assertCurrentModel "waiting"
        , test "Process.sleep" <|
            \() ->
                { init =
                    ( "waiting"
                    , Process.sleep (5 * Time.second)
                        |> Task.andThen (\_ -> Task.succeed "5 seconds passed")
                        |> Task.perform identity
                    )
                , update = \value mode -> ( value, Testable.Cmd.none )
                , view = \model -> text ""
                }
                    |> TestContext.startForTest
                    |> TestContext.advanceTime (5 * Time.second)
                    |> TestContext.assertCurrentModel "5 seconds passed"
        , test "sending a value through a port" <|
            \() ->
                { init =
                    ( Nothing
                    , Testable.Cmd.none
                    )
                , update = \_ _ -> ( Nothing, Testable.Cmd.wrap <| outgoingPort "foo" )
                , view = \model -> text ""
                }
                    |> TestContext.startForTest
                    |> TestContext.update Inc
                    |> TestContext.assertCalled (outgoingPort "foo")
        , test "asserting text" <|
            \() ->
                { init =
                    ( Nothing
                    , Testable.Cmd.none
                    )
                , update = \_ _ -> ( Nothing, Testable.Cmd.none )
                , view = \model -> text "foo"
                }
                    |> TestContext.startForTest
                    |> TestContext.assertText (Expect.equal "foo")
        , test "querying views" <|
            \() ->
                { init =
                    ( Nothing
                    , Testable.Cmd.none
                    )
                , update = \_ _ -> ( Nothing, Testable.Cmd.none )
                , view = \model -> div [] [ text "foo", input [] [ text "bar" ] ]
                }
                    |> TestContext.startForTest
                    |> TestContext.find [ tag "input" ]
                    |> TestContext.assertText (Expect.equal "bar")
        ]
