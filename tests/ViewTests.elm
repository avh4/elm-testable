module ViewTests exposing (all)

import Html
import Html.Events exposing (onClick)
import Test exposing (..)
import Test.Html.Events as Events
import Test.Html.Query as Query exposing (..)
import Test.Html.Selector as Selector
import TestContext exposing (TestContext)
import Expect


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


all : Test
all =
    describe "View"
        [ test "verifying an initial view" <|
            \() ->
                htmlProgram
                    |> TestContext.query (find [ Selector.tag "h1" ])
                    |> TestContext.expectView (has [ Selector.text "Title!" ])
        , test "view changes after update" <|
            \() ->
                htmlProgram
                    |> TestContext.update "strong"
                    |> TestContext.expectView (has [ Selector.tag "strong" ])
        , test "triggers events" <|
            \() ->
                htmlProgram
                    |> TestContext.query (find [ Selector.tag "button" ])
                    |> TestContext.trigger Events.Click
                    |> TestContext.expectView (has [ Selector.tag "p" ])
        , test "query for multiple nodes" <|
            \() ->
                htmlProgram
                    |> TestContext.query (find [ Selector.tag "button" ])
                    |> TestContext.trigger Events.Click
                    |> TestContext.queryToAll (findAll [ Selector.tag "p" ])
                    |> TestContext.query (find [ Selector.tag "button" ])
                    |> TestContext.expectViewAll (count (Expect.equal 1))
        ]
