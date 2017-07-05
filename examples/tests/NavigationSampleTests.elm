module NavigationSampleTests exposing (all)

import Expect
import NavigationSample exposing (program)
import Test exposing (..)
import Test.Html.Event as Event
import Test.Html.Query exposing (..)
import Test.Html.Selector exposing (..)
import TestContext exposing (..)


all : Test
all =
    describe "NavigationSample"
        [ test "renders navigation history" <|
            \() ->
                NavigationSample.program
                    |> start
                    |> simulate (find [ class "bears" ]) Event.click
                    |> simulate (find [ class "cats" ]) Event.click
                    |> expectView
                    |> find [ class "history" ]
                    |> Expect.all
                        [ has [ text "#bears" ]
                        , has [ text "#cats" ]
                        ]
        , test "works for user initiated navigation" <|
            \() ->
                NavigationSample.program
                    |> start
                    |> navigate "#cats"
                    |> expectView
                    |> find [ class "history" ]
                    |> has [ text "#cats" ]
        ]
