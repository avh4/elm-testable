module ViewTests exposing (all)

import Expect
import Html
import Html.Events exposing (onClick)
import Test exposing (..)
import Test.Html.Events as Events
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import TestContext exposing (TestContext)
import TestContextInternal


htmlProgram : TestContext (List String) String
htmlProgram =
    { model = []
    , update = \msg model -> msg :: model
    , view =
        \model ->
            Html.section []
                [ Html.h1 [] [ Html.text "Title!" ]
                , model
                    |> List.map (\tag -> Html.node tag [] [])
                    |> Html.div []
                , Html.button [ onClick "p" ] []
                ]
    }
        |> Html.beginnerProgram
        |> TestContext.start


expectError : String -> TestContext model msg -> Expect.Expectation
expectError expectedError context =
    case context of
        TestContextInternal.TestContext _ ->
            Expect.fail "TestContext should have an error an it doesn't"

        TestContextInternal.TestError { error } ->
            Expect.equal expectedError error


all : Test
all =
    describe "View"
        [ test "verifying an initial view" <|
            \() ->
                htmlProgram
                    |> TestContext.expectView
                    |> Query.find [ Selector.tag "h1" ]
                    |> Query.has [ Selector.text "Title!" ]
        , test "view changes after update" <|
            \() ->
                htmlProgram
                    |> TestContext.update "strong"
                    |> TestContext.expectView
                    |> Query.has [ Selector.tag "strong" ]
        , test "triggers events" <|
            \() ->
                htmlProgram
                    |> TestContext.simulate (Query.find [ Selector.tag "button" ]) Events.Click
                    |> TestContext.expectView
                    |> Query.has [ Selector.tag "p" ]
        , test "fails when triggering events on a not found element" <|
            \() ->
                htmlProgram
                    |> TestContext.simulate (Query.find [ Selector.tag "foo" ]) Events.Click
                    |> expectError "Query.find always expects to find 1 element, but it found 0 instead."
        , test "fails when triggersingevents on an element that does not handle that event" <|
            \() ->
                htmlProgram
                    |> TestContext.simulate (Query.find [ Selector.tag "button" ]) Events.DoubleClick
                    |> expectError "Failed to decode string"
        ]
