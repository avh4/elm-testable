module TestContext
    exposing
        ( TestContext
        , advanceTime
        , back
        , done
        , expectCmd
        , expectModel
        , expectView
        , forward
        , navigate
        , send
        , simulate
        , start
        , startWithFlags
        , update
        )

{-| A `TestContext` allows you to manage the lifecycle of an Elm app,
allowing you to write integration tests.

@docs TestContext


# Managing lifecycle

@docs start, startWithFlags, update


# Simulating Effects

@docs advanceTime, send, simulate


# Navigation

@docs navigate, back, forward


# Assertion

@docs expectCmd, expectModel, expectView, done

-}

import Expect exposing (Expectation)
import Json.Decode exposing (Value)
import Test.Html.Query
import TestContextInternal as Internal
import Time exposing (Time)


{-| Wraps a Program plus its context for making elm-testable assertions
-}
type alias TestContext model msg =
    Internal.TestContext model msg


{-| Create a `TestContext` for the given Program
-}
start : Program Never model msg -> TestContext model msg
start realProgram =
    Internal.start realProgram


{-| Create a `TestContext` for a Program with flags
-}
startWithFlags : flags -> Program flags model msg -> TestContext model msg
startWithFlags flags realProgram =
    Internal.startWithFlags flags realProgram


{-| Update your program with a message, exercising its update flow
-}
update : msg -> TestContext model msg -> TestContext model msg
update msg context =
    Internal.update msg context


{-| Simulate a value being sent through a port
-}
send :
    ((value -> msg) -> Sub msg)
    -> value
    -> TestContext model msg
    -> TestContext model msg
send subPort value context =
    Internal.send subPort value context


{-| Assert that a Cmd was called
-}
expectCmd : Cmd msg -> TestContext model msg -> Expectation
expectCmd expected context =
    Internal.expectCmd expected context


{-| Advances time, triggering delayed processes
-}
advanceTime : Time -> TestContext model msg -> TestContext model msg
advanceTime dt context =
    Internal.advanceTime dt context


{-| Write an assertion to check the current state of the Model
-}
expectModel : (model -> Expectation) -> TestContext model msg -> Expectation
expectModel check context =
    Internal.expectModel check context


{-| Write an assertion to check the current state of the View
-}
expectView : TestContext model msg -> Test.Html.Query.Single msg
expectView context =
    Internal.expectView context


{-| Simulate a DOM event being triggered on the view
-}
simulate : (Test.Html.Query.Single msg -> Test.Html.Query.Single msg) -> ( String, Value ) -> TestContext model msg -> TestContext model msg
simulate eventTrigger event context =
    Internal.simulate eventTrigger event context


{-| Simulates a browser navigation by the user
-}
navigate : String -> TestContext model msg -> TestContext model msg
navigate url context =
    Internal.navigate url context


{-| Simulates a user hitting the back button on the browser
-}
back : TestContext model msg -> TestContext model msg
back context =
    Internal.back context


{-| Simulates a user hitting the forward button on the browser
-}
forward : TestContext model msg -> TestContext model msg
forward context =
    Internal.forward context


{-| Ends the test ensuring that no previous actions had errors
-}
done : TestContext model msg -> Expectation
done =
    Internal.done
