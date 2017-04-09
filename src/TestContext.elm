module TestContext
    exposing
        ( TestContext
        , start
        , startWithFlags
        , model
        , update
        , send
        , expectCmd
        , advanceTime
        , expect
        )

import Expect exposing (Expectation)
import TestContextInternal as Internal
import Time exposing (Time)


type alias TestContext model msg =
    Internal.TestContext model msg


start : Program Never model msg -> TestContext model msg
start realProgram =
    Internal.start realProgram


startWithFlags : flags -> Program flags model msg -> TestContext model msg
startWithFlags flags realProgram =
    Internal.startWithFlags flags realProgram


model : TestContext model msg -> model
model context =
    Internal.model context


update : msg -> TestContext model msg -> TestContext model msg
update msg context =
    Internal.update msg context


send :
    ((value -> msg) -> Sub msg)
    -> value
    -> TestContext model msg
    -> Result String (TestContext model msg)
send subPort value context =
    Internal.send subPort value context


expectCmd : Cmd msg -> TestContext model msg -> Expectation
expectCmd expected context =
    Internal.expectCmd expected context


advanceTime : Time -> TestContext model msg -> TestContext model msg
advanceTime dt context =
    Internal.advanceTime dt context


expect : (TestContext model msg -> a) -> (a -> Expectation) -> TestContext model msg -> Expectation
expect =
    Internal.expect
