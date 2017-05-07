module TestContextWithMocks
    exposing
        ( TestContext
        , SingleQueryTest
        , MultipleQueryTest
        , MockTask
        , toTask
        , mockTask
        , start
        , startWithFlags
        , expectModel
        , update
        , expectMockTask
        , resolveMockTask
        , send
        , expectCmd
        , advanceTime
        )

{-| This is a TestContext that allows mock Tasks. You probably want to use
the `TestContext` module instead unless you are really sure of what you are doing.
-}

import TestContextInternal as Internal
import Expect exposing (Expectation)
import Time exposing (Time)


type alias TestContext query model msg =
    Internal.TestContext query model msg


type alias MockTask x a =
    Internal.MockTask x a


type alias SingleQueryTest model msg =
    Internal.SingleQueryTest model msg


type alias MultipleQueryTest model msg =
    Internal.MultipleQueryTest model msg


toTask : MockTask x a -> Platform.Task x a
toTask mockTask =
    Internal.toTask mockTask


mockTask : String -> MockTask x a
mockTask =
    Internal.mockTask


startWithFlags : flags -> Program flags model msg -> SingleQueryTest model msg
startWithFlags flags realProgram =
    Internal.startWithFlags flags realProgram


start : Program Never model msg -> SingleQueryTest model msg
start realProgram =
    Internal.start realProgram


expectModel : (model -> Expectation) -> TestContext query model msg -> Expectation
expectModel check context =
    Internal.expectModel check context


update : msg -> TestContext query model msg -> SingleQueryTest model msg
update msg context =
    Internal.update msg context


expectMockTask : MockTask x a -> TestContext query model msg -> Expectation
expectMockTask whichMock context =
    Internal.expectMockTask whichMock context


resolveMockTask : MockTask x a -> Result x a -> TestContext query model msg -> SingleQueryTest model msg
resolveMockTask mock result context =
    Internal.resolveMockTask mock result context


send :
    ((value -> msg) -> Sub msg)
    -> value
    -> TestContext query model msg
    -> SingleQueryTest model msg
send subPort value context =
    Internal.send subPort value context


expectCmd : Cmd msg -> TestContext query model msg -> Expectation
expectCmd expected context =
    Internal.expectCmd expected context


advanceTime : Time -> TestContext query model msg -> SingleQueryTest model msg
advanceTime dt context =
    Internal.advanceTime dt context
