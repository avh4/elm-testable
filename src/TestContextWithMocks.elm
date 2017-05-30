module TestContextWithMocks
    exposing
        ( MockTask
        , TestContext
        , advanceTime
        , expectCmd
        , expectMockTask
        , expectModel
        , mockTask
        , resolveMockTask
        , send
        , start
        , startWithFlags
        , toTask
        , update
        )

{-| This is a TestContext that allows mock Tasks. You probably want to use
the `TestContext` module instead unless you are really sure of what you are doing.
-}

import Expect exposing (Expectation)
import TestContextInternal as Internal
import Time exposing (Time)


type alias TestContext model msg =
    Internal.TestContext model msg


type alias MockTask x a =
    Internal.MockTask x a


toTask : MockTask x a -> Platform.Task x a
toTask mockTask =
    Internal.toTask mockTask


mockTask : String -> MockTask x a
mockTask =
    Internal.mockTask


startWithFlags : flags -> Program flags model msg -> TestContext model msg
startWithFlags flags realProgram =
    Internal.startWithFlags flags realProgram


start : Program Never model msg -> TestContext model msg
start realProgram =
    Internal.start realProgram


expectModel : (model -> Expectation) -> TestContext model msg -> Expectation
expectModel check context =
    Internal.expectModel check context


update : msg -> TestContext model msg -> TestContext model msg
update msg context =
    Internal.update msg context


expectMockTask : MockTask x a -> TestContext model msg -> Expectation
expectMockTask whichMock context =
    Internal.expectMockTask whichMock context


resolveMockTask : MockTask x a -> Result x a -> TestContext model msg -> TestContext model msg
resolveMockTask mock result context =
    Internal.resolveMockTask mock result context


send :
    ((value -> msg) -> Sub msg)
    -> value
    -> TestContext model msg
    -> TestContext model msg
send subPort value context =
    Internal.send subPort value context


expectCmd : Cmd msg -> TestContext model msg -> Expectation
expectCmd expected context =
    Internal.expectCmd expected context


advanceTime : Time -> TestContext model msg -> TestContext model msg
advanceTime dt context =
    Internal.advanceTime dt context
