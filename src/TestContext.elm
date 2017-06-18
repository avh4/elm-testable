module TestContext
    exposing
        ( TestContext
        , advanceTime
        , done
        , expectCmd
        , expectModel
        , expectView
        , send
        , simulate
        , start
        , startWithFlags
        , update
        )

import Expect exposing (Expectation)
import Test.Html.Events exposing (Event)
import Test.Html.Query
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


update : msg -> TestContext model msg -> TestContext model msg
update msg context =
    Internal.update msg context


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


expectModel : (model -> Expectation) -> TestContext model msg -> Expectation
expectModel check context =
    Internal.expectModel check context


expectView : TestContext model msg -> Test.Html.Query.Single msg
expectView context =
    Internal.expectView context


simulate : (Test.Html.Query.Single msg -> Test.Html.Query.Single msg) -> Event -> TestContext model msg -> TestContext model msg
simulate eventTrigger event context =
    Internal.simulate eventTrigger event context


done : TestContext model msg -> Expectation
done =
    Internal.done
