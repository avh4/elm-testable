module ViewTests exposing (all)

import Html
import Html.Events exposing (onClick)
import Html.Attributes
import Test exposing (..)
import Test.Html.Events as Events
import Test.Html.Selector as Selector
import TestContext exposing (SingleQueryTest)
import Test.View exposing (..)
import Expect


htmlProgram : SingleQueryTest (List String) String
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
                    |> find [ Selector.tag "h1" ]
                    |> has [ Selector.text "Title!" ]
        , test "view changes after update" <|
            \() ->
                htmlProgram
                    |> TestContext.update "strong"
                    |> has [ Selector.tag "strong" ]
        , test "triggers events" <|
            \() ->
                htmlProgram
                    |> find [ Selector.class "first-button" ]
                    |> trigger Events.Click
                    |> has [ Selector.tag "p" ]
        , test "query for multiple nodes" <|
            \() ->
                htmlProgram
                    |> find [ Selector.class "first-button" ]
                    |> trigger Events.Click
                    |> findAll [ Selector.tag "p" ]
                    |> count (Expect.equal 1)
        , test "triggers multiple events" <|
            \() ->
                htmlProgram
                    |> find [ Selector.class "first-button" ]
                    |> trigger Events.Click
                    |> find [ Selector.class "second-button" ]
                    |> trigger Events.Click
                    |> findAll [ Selector.tag "p" ]
                    |> count (Expect.equal 2)
        ]
