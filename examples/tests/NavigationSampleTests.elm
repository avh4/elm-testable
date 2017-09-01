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
                    |> startWithLocation "http://example.com/"
                    |> simulate (findAll [ tag "button" ] >> index 2) Event.click
                    |> simulate (findAll [ tag "button" ] >> index 4) Event.click
                    |> expectView
                    |> Expect.all
                        [ has [ text "show blog 42" ]
                        , has [ text "search for cats" ]
                        ]
        , test "works for user initiated navigation" <|
            \() ->
                NavigationSample.program
                    |> startWithLocation "http://example.com/"
                    |> navigate "/blog/?search=dogs"
                    |> expectView
                    |> has [ text "search for dogs" ]
        ]
