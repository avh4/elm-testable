module TestContext
    exposing
        ( TestContext
        , SingleQuery
        , MultipleQuery
        , start
        , startWithFlags
        , update
        , send
        , expectCmd
        , advanceTime
        , expectModel
        , done
        )

import Expect exposing (Expectation)
import TestContextInternal as Internal
import Time exposing (Time)


type alias TestContext query model msg =
    Internal.TestContext query model msg


type alias SingleQuery =
    Internal.SingleQuery


type alias MultipleQuery =
    Internal.MultipleQuery


start : Program Never model msg -> TestContext SingleQuery model msg
start realProgram =
    Internal.start realProgram


startWithFlags : flags -> Program flags model msg -> TestContext SingleQuery model msg
startWithFlags flags realProgram =
    Internal.startWithFlags flags realProgram


update : msg -> TestContext query model msg -> TestContext SingleQuery model msg
update msg context =
    Internal.update msg context


send :
    ((value -> msg) -> Sub msg)
    -> value
    -> TestContext query model msg
    -> TestContext SingleQuery model msg
send subPort value context =
    Internal.send subPort value context


expectCmd : Cmd msg -> TestContext query model msg -> Expectation
expectCmd expected context =
    Internal.expectCmd expected context


advanceTime : Time -> TestContext query model msg -> TestContext SingleQuery model msg
advanceTime dt context =
    Internal.advanceTime dt context


expectModel : (model -> Expectation) -> TestContext query model msg -> Expectation
expectModel check context =
    Internal.expectModel check context


done : TestContext query model msg -> Expectation
done =
    Internal.done
