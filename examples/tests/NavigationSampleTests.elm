module NavigationSampleTests exposing (all)

import Expect
import NavigationSample exposing (Msg(..))
import Test exposing (..)
import Test.Html.Events as Events
import Test.Html.Query exposing (..)
import Test.Html.Selector exposing (..)
import TestContext exposing (..)


all : Test
all =
    describe "NavigationSample"
        [ test "shows navigation " <|
            \() ->
                NavigationSample.main
                    |> start
                    |> simulate (find [ class "bears" ]) Events.Click
                    |> simulate (find [ class "cats" ]) Events.Click
                    |> expectView
                    |> find [ class "history" ]
                    |> Expect.all
                        [ has [ text "#bears" ]
                        , has [ text "#cats" ]
                        ]
        ]
