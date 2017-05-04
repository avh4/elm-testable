module TestContext
    exposing
        ( TestContext
        , SingleQuery
        , MultipleQuery
        , start
        , startWithFlags
        , update
        , query
        , queryToAll
        , queryFromAll
        , trigger
        , send
        , expectCmd
        , advanceTime
        , expectModel
        , expectView
        , expectViewAll
        , done
        )

import Expect exposing (Expectation)
import TestContextInternal as Internal
import Test.Html.Query
import Test.Html.Events
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


expectView : (Test.Html.Query.Single -> Expectation) -> TestContext SingleQuery model msg -> Expectation
expectView check context =
    Internal.expectView check context


expectViewAll : (Test.Html.Query.Multiple -> Expectation) -> TestContext MultipleQuery model msg -> Expectation
expectViewAll check context =
    Internal.expectViewAll check context


query : (Test.Html.Query.Single -> Test.Html.Query.Single) -> TestContext SingleQuery model msg -> TestContext SingleQuery model msg
query singleQuery context =
    Internal.query singleQuery context


queryFromAll : (Test.Html.Query.Multiple -> Test.Html.Query.Single) -> TestContext MultipleQuery model msg -> TestContext SingleQuery model msg
queryFromAll multipleQuery context =
    Internal.queryFromAll multipleQuery context


queryToAll : (Test.Html.Query.Single -> Test.Html.Query.Multiple) -> TestContext SingleQuery model msg -> TestContext MultipleQuery model msg
queryToAll multipleQuery context =
    Internal.queryToAll multipleQuery context


trigger : Test.Html.Events.Event -> TestContext SingleQuery model msg -> TestContext SingleQuery model msg
trigger event context =
    Internal.trigger event context


done : TestContext query model msg -> Expectation
done =
    Internal.done
