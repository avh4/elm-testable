module ViewTests exposing (all)

import Html
import Html.Events exposing (onClick)
import Html.Attributes
import Test exposing (..)
import Test.Html.Events as Events
import Test.Html.Query as Query exposing (..)
import Test.Html.Selector as Selector
import TestContext exposing (TestContext, SingleQuery)
import Test.View exposing (..)
import Expect


htmlProgram : TestContext SingleQuery (List String) String
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
                , Html.button [ Html.Attributes.class "first-button", onClick "p" ] []
                , Html.button [ Html.Attributes.class "second-button", onClick "p" ] []
                ]
    }
        |> Html.beginnerProgram
        |> TestContext.start


all : Test
all =
    describe "View"
        [ test "verifying an initial view" <|
            \() ->
                htmlProgram
                    |> query (find [ Selector.tag "h1" ])
                    |> expectView (has [ Selector.text "Title!" ])
        , test "view changes after update" <|
            \() ->
                htmlProgram
                    |> TestContext.update "strong"
                    |> expectView (has [ Selector.tag "strong" ])
        , test "triggers events" <|
            \() ->
                htmlProgram
                    |> query (find [ Selector.class "first-button" ])
                    |> trigger Events.Click
                    |> expectView (has [ Selector.tag "p" ])
        , test "query for multiple nodes" <|
            \() ->
                htmlProgram
                    |> query (find [ Selector.class "first-button" ])
                    |> trigger Events.Click
                    |> queryToAll (findAll [ Selector.tag "p" ])
                    |> expectViewAll (count (Expect.equal 1))
        , test "triggers multiple events" <|
            \() ->
                htmlProgram
                    |> query (find [ Selector.class "first-button" ])
                    |> trigger Events.Click
                    |> query (find [ Selector.class "second-button" ])
                    |> trigger Events.Click
                    |> queryToAll (findAll [ Selector.tag "p" ])
                    |> expectViewAll (count (Expect.equal 2))
        ]
