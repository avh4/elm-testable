module Testable.TestContext exposing (Component, TestContext, startForTest, update, currentModel, assertCurrentModel, assertHttpRequest, assertNoPendingHttpRequests, resolveHttpRequest, advanceTime, click)

{-| A `TestContext` allows you to manage the lifecycle of an Elm component that
uses `Testable.Effects`.  Using `TestContext`, you can write tests that exercise
the entire lifecycle of your component.

@docs Component, TestContext, startForTest, update

# Inspecting
@docs currentModel, assertCurrentModel, assertHttpRequest, assertNoPendingHttpRequests

# Simulating Effects
@docs resolveHttpRequest, advanceTime, click
-}

import ElmTest as Test exposing (Assertion)
import Html exposing (Html)
import HtmlToString
import Json.Encode as Json
import String
import Testable.Cmd
import Testable.EffectsLog as EffectsLog exposing (EffectsLog)
import Testable.Http as Http
import Time exposing (Time)


{-| A component that can be used to create a `TestContext`
-}
type alias Component msg model =
    { init : ( model, Testable.Cmd.Cmd msg )
    , update : msg -> model -> ( model, Testable.Cmd.Cmd msg )
    , view : model -> Html msg
    }


{-| The representation of the current state of a testable component, including
a representaiton of any pending Effects.
-}
type TestContext msg model
    = TestContext
        { component : Component msg model
        , state :
            Result (List String)
                { model : model
                , effectsLog : EffectsLog msg
                }
        }


{-| Create a `TestContext` for the given Component
-}
startForTest : Component msg model -> TestContext msg model
startForTest component =
    let
        ( initialState, initialEffects ) =
            component.init
    in
        TestContext
            { component = component
            , state =
                Ok
                    { model = initialState
                    , effectsLog = EffectsLog.empty
                    }
            }
            |> applyEffects initialEffects


{-| Apply an msg to the component in a given TestContext
-}
update : msg -> TestContext msg model -> TestContext msg model
update msg (TestContext context) =
    case context.state of
        Ok state ->
            let
                ( newModel, newEffects ) =
                    context.component.update msg state.model
            in
                TestContext
                    { context
                        | state = Ok { state | model = newModel }
                    }
                    |> applyEffects newEffects

        Err errors ->
            TestContext
                { context
                    | state = Err (("update " ++ toString msg ++ " applied to an TestContext with previous errors") :: errors)
                }


applyEffects : Testable.Cmd.Cmd msg -> TestContext msg model -> TestContext msg model
applyEffects newEffects (TestContext context) =
    case context.state of
        Err errors ->
            TestContext context

        Ok { model, effectsLog } ->
            case EffectsLog.insert newEffects effectsLog of
                ( newEffectsLog, immediateMsgs ) ->
                    List.foldl update
                        (TestContext
                            { context
                                | state =
                                    Ok
                                        { model = model
                                        , effectsLog = newEffectsLog
                                        }
                            }
                        )
                        immediateMsgs


{-| Assert that a given Http.Request has been made by the componet under test
-}
assertHttpRequest : Http.Request -> TestContext msg model -> Assertion
assertHttpRequest request (TestContext context) =
    case context.state of
        Err errors ->
            Test.fail
                ("Expected an HTTP request to have been made:"
                    ++ "\n    Expected: "
                    ++ toString request
                    ++ "\n    Actual:"
                    ++ "\n      TextContext had previous errors:"
                    ++ String.join "\n        " ("" :: errors)
                )

        Ok { model, effectsLog } ->
            if EffectsLog.containsHttpMsg request effectsLog then
                Test.pass
            else
                Test.fail
                    ("Expected an HTTP request to have been made:"
                        ++ "\n    Expected: "
                        ++ toString request
                        ++ "\n    Actual: "
                        ++ toString effectsLog
                    )


{-| Simulate an HTTP response
-}
resolveHttpRequest : Http.Request -> Result Http.RawError Http.Response -> TestContext msg model -> TestContext msg model
resolveHttpRequest request response (TestContext context) =
    case context.state of
        Err errors ->
            TestContext
                { context
                    | state = Err (("resolveHttpRequest " ++ toString request ++ " applied to an TestContext with previous errors") :: errors)
                }

        Ok { model, effectsLog } ->
            case
                EffectsLog.httpMsg request response effectsLog
                    |> Result.fromMaybe ("No pending HTTP request: " ++ toString request)
            of
                Ok ( newLog, msgs ) ->
                    List.foldl update
                        (TestContext { context | state = Ok { model = model, effectsLog = newLog } })
                        msgs

                Err message ->
                    TestContext { context | state = Err [ message ] }


{-| Ensure that there are no pending HTTP requests
-}
assertNoPendingHttpRequests : TestContext msg model -> Assertion
assertNoPendingHttpRequests (TestContext context) =
    case context.state of
        Err errors ->
            Test.fail
                ("Expected no pending HTTP requests, but TextContext had previous errors:"
                    ++ String.join "\n    " ("" :: errors)
                )

        Ok { effectsLog } ->
            Test.assertEqual [] (EffectsLog.httpRequests effectsLog)


{-| Simulate the passing of time
-}
advanceTime : Time -> TestContext msg model -> TestContext msg model
advanceTime milliseconds (TestContext context) =
    case context.state of
        Err errors ->
            TestContext
                { context
                    | state = Err (("advanceTime " ++ toString milliseconds ++ " applied to an TestContext with previous errors") :: errors)
                }

        Ok { model, effectsLog } ->
            case
                EffectsLog.sleepMsg milliseconds effectsLog
            of
                ( newLog, msgs ) ->
                    List.foldl update
                        (TestContext { context | state = Ok { model = model, effectsLog = newLog } })
                        msgs


{-| Get the current state of the component under test
-}
currentModel : TestContext msg model -> Result (List String) model
currentModel (TestContext context) =
    context.state |> Result.map .model


{-| A convenient way to assert about the current state of the component under test
-}
assertCurrentModel : model -> TestContext msg model -> Assertion
assertCurrentModel expectedModel context =
    context
        |> currentModel
        |> Test.assertEqual (Ok expectedModel)


{-| -}
click : TestContext msg model -> TestContext msg model
click (TestContext context) =
    let
        f =
            ()
    in
        case
            currentModel (TestContext context)
                |> Result.map context.component.view
                |> Result.map HtmlToString.nodeTypeFromHtml
                |> Result.formatError (toString)
                |> flip Result.andThen (HtmlToString.findOne "button")
                |> flip Result.andThen (HtmlToString.triggerEvent "click" Json.null)
        of
            Ok msg ->
                update msg (TestContext context)

            Err message ->
                TestContext { context | state = Err [ message ] }
