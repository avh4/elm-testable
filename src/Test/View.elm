module Test.View
    exposing
        ( query
        , queryToAll
        , queryFromAll
        , trigger
        , expectView
        , expectViewAll
        )

import Expect exposing (Expectation)
import TestContextInternal as Internal exposing (TestContext(..), SingleQuery, MultipleQuery)
import Test.Html.Query
import Test.Html.Events


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
