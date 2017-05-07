module Test.View
    exposing
        ( find
        , findAll
        , trigger
        , has
        , count
        )

import Expect exposing (Expectation)
import TestContextInternal as Internal exposing (TestContext(..), SingleQueryTest, MultipleQueryTest)
import Test.Html.Query as Query
import Test.Html.Selector exposing (Selector)
import Test.Html.Events


find : List Selector -> SingleQueryTest model msg -> SingleQueryTest model msg
find =
    Query.find >> Internal.query


findAll : List Selector -> SingleQueryTest model msg -> MultipleQueryTest model msg
findAll =
    Query.findAll >> Internal.queryToAll


children : List Selector -> SingleQueryTest model msg -> MultipleQueryTest model msg
children =
    Query.children >> Internal.queryToAll


first : MultipleQueryTest model msg -> SingleQueryTest model msg
first =
    Query.first |> Internal.queryFromAll


index : Int -> MultipleQueryTest model msg -> SingleQueryTest model msg
index =
    Query.index >> Internal.queryFromAll


count : (Int -> Expectation) -> MultipleQueryTest model msg -> Expectation
count =
    Query.count >> Internal.expectViewAll


has : List Selector -> SingleQueryTest model msg -> Expectation
has =
    Query.has >> Internal.expectView


hasNot : List Selector -> SingleQueryTest model msg -> Expectation
hasNot =
    Query.hasNot >> Internal.expectView


each : (Query.Single msg -> Expectation) -> MultipleQueryTest model msg -> Expectation
each =
    Query.each >> Internal.expectViewAll


trigger : Test.Html.Events.Event -> SingleQueryTest model msg -> SingleQueryTest model msg
trigger event =
    Internal.trigger event
