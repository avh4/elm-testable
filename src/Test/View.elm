module Test.View
    exposing
        ( find
        , findAll
        , trigger
        , has
        , count
        )

import Expect exposing (Expectation)
import TestContextInternal as Internal exposing (TestContext(..), SingleQuery, MultipleQuery)
import Test.Html.Query
import Test.Html.Selector exposing (Selector)
import Test.Html.Events


find : List Selector -> TestContext SingleQuery model msg -> TestContext SingleQuery model msg
find =
    Test.Html.Query.find >> Internal.query


findAll : List Selector -> TestContext SingleQuery model msg -> TestContext MultipleQuery model msg
findAll =
    Test.Html.Query.findAll >> Internal.queryToAll


children : List Selector -> TestContext SingleQuery model msg -> TestContext MultipleQuery model msg
children =
    Test.Html.Query.children >> Internal.queryToAll


first : TestContext MultipleQuery model msg -> TestContext SingleQuery model msg
first =
    Test.Html.Query.first |> Internal.queryFromAll


index : Int -> TestContext MultipleQuery model msg -> TestContext SingleQuery model msg
index =
    Test.Html.Query.index >> Internal.queryFromAll


count : (Int -> Expectation) -> TestContext MultipleQuery model msg -> Expectation
count =
    Test.Html.Query.count >> Internal.expectViewAll


has : List Selector -> TestContext SingleQuery model msg -> Expectation
has =
    Test.Html.Query.has >> Internal.expectView


hasNot : List Selector -> TestContext SingleQuery model msg -> Expectation
hasNot =
    Test.Html.Query.hasNot >> Internal.expectView


each : (SingleQuery -> Expectation) -> TestContext MultipleQuery model msg -> Expectation
each =
    Test.Html.Query.each >> Internal.expectViewAll


trigger : Test.Html.Events.Event -> TestContext SingleQuery model msg -> TestContext SingleQuery model msg
trigger event =
    Internal.trigger event
