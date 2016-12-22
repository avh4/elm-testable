module Testable.TestContext exposing (Component, TestContext, startForTest, update, currentModel, assertCurrentModel, assertHttpRequest, assertHttpRequestWithSettings, assertNoPendingHttpRequests, resolveHttpRequest, resolveHttpRequestWithSettings, advanceTime, assertCalled)

{-| A `TestContext` allows you to manage the lifecycle of an Elm component that
uses `Testable.Effects`.  Using `TestContext`, you can write tests that exercise
the entire lifecycle of your component.

@docs Component, TestContext, startForTest, update

# Inspecting
@docs currentModel, assertCurrentModel, assertHttpRequest, assertHttpRequestWithSettings, assertNoPendingHttpRequests, assertCalled

# Simulating Effects
@docs resolveHttpRequest, resolveHttpRequestWithSettings, advanceTime
-}

import Expect exposing (Expectation)
import String
import Testable.Cmd
import Testable.EffectsLog as EffectsLog exposing (EffectsLog, containsCmd)
import Testable.Http as Http
import Time exposing (Time)
import Platform.Cmd


{-| A component that can be used to create a `TestContext`
-}
type alias Component msg model =
    { init : ( model, Testable.Cmd.Cmd msg )
    , update : msg -> model -> ( model, Testable.Cmd.Cmd msg )
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


{-| Assert that a given Http.Request has been made by the component under test
with the Http.defaultSettings
-}
assertHttpRequest : Http.Request -> TestContext msg model -> Expectation
assertHttpRequest request (TestContext context) =
    case context.state of
        Err errors ->
            Expect.fail
                ("Expected an HTTP request to have been made:"
                    ++ "\n    Expected: "
                    ++ toString request
                    ++ "\n    Actual:"
                    ++ "\n      TextContext had previous errors:"
                    ++ String.join "\n        " ("" :: errors)
                )

        Ok { model, effectsLog } ->
            if EffectsLog.containsHttpMsg Http.defaultSettings request effectsLog then
                Expect.pass
            else
                Expect.fail
                    ("Expected an HTTP request to have been made:"
                        ++ "\n    Expected: "
                        ++ toString request
                        ++ "\n    Actual: "
                        ++ toString effectsLog
                    )


{-| Assert that a given Http.Request has been made by the component under test
with the given Http settings
-}
assertHttpRequestWithSettings : Http.Settings -> Http.Request -> TestContext msg model -> Expectation
assertHttpRequestWithSettings settings request (TestContext context) =
    case context.state of
        Err errors ->
            Expect.fail
                ("Expected an HTTP request to have been made:"
                    ++ "\n    Expected: "
                    ++ toString request
                    ++ " with settings "
                    ++ toString settings
                    ++ "\n    Actual:"
                    ++ "\n      TextContext had previous errors:"
                    ++ String.join "\n        " ("" :: errors)
                )

        Ok { model, effectsLog } ->
            if EffectsLog.containsHttpMsg settings request effectsLog then
                Expect.pass
            else
                Expect.fail
                    ("Expected an HTTP request to have been made:"
                        ++ "\n    Expected: "
                        ++ toString request
                        ++ " with settings "
                        ++ toString settings
                        ++ "\n    Actual: "
                        ++ toString effectsLog
                    )


{-| Simulate an HTTP response to a request made with the Http.defaultSettings
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
                EffectsLog.httpMsg Http.defaultSettings request response effectsLog
                    |> Result.fromMaybe ("No pending HTTP request: " ++ toString request)
            of
                Ok ( newLog, msgs ) ->
                    List.foldl update
                        (TestContext { context | state = Ok { model = model, effectsLog = newLog } })
                        msgs

                Err message ->
                    TestContext { context | state = Err [ message ] }


{-| Simulate an HTTP response to a request made with the given Http settings
-}
resolveHttpRequestWithSettings : Http.Settings -> Http.Request -> Result Http.RawError Http.Response -> TestContext msg model -> TestContext msg model
resolveHttpRequestWithSettings settings request response (TestContext context) =
    case context.state of
        Err errors ->
            TestContext
                { context
                    | state = Err (("resolveHttpRequest " ++ toString request ++ " with settings " ++ toString settings ++ " applied to an TestContext with previous errors") :: errors)
                }

        Ok { model, effectsLog } ->
            case
                EffectsLog.httpMsg settings request response effectsLog
                    |> Result.fromMaybe ("No pending HTTP request: " ++ toString request ++ " with settings " ++ toString settings)
            of
                Ok ( newLog, msgs ) ->
                    List.foldl update
                        (TestContext { context | state = Ok { model = model, effectsLog = newLog } })
                        msgs

                Err message ->
                    TestContext { context | state = Err [ message ] }


{-| Ensure that there are no pending HTTP requests
-}
assertNoPendingHttpRequests : TestContext msg model -> Expectation
assertNoPendingHttpRequests (TestContext context) =
    case context.state of
        Err errors ->
            Expect.fail
                ("Expected no pending HTTP requests, but TextContext had previous errors:"
                    ++ String.join "\n    " ("" :: errors)
                )

        Ok { effectsLog } ->
            Expect.equal [] (EffectsLog.httpRequests effectsLog)


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
assertCurrentModel : model -> TestContext msg model -> Expectation
assertCurrentModel expectedModel context =
    context
        |> currentModel
        |> Expect.equal (Ok expectedModel)


{-| Assert that a cmd was called
-}
assertCalled : Platform.Cmd.Cmd msg -> TestContext msg model -> Expectation
assertCalled expectedCmd (TestContext context) =
    case context.state of
        Err errors ->
            Expect.fail
                ("Expected that a cmd was called, but TextContext had previous errors:"
                    ++ String.join "\n    " ("" :: errors)
                )

        Ok { effectsLog } ->
            if containsCmd expectedCmd effectsLog then
                Expect.pass
            else
                Expect.equal [ expectedCmd ] (EffectsLog.wrappedCmds effectsLog)
