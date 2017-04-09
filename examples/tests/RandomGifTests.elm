module RandomGifTests exposing (..)

import TestContext exposing (..)
import Expect exposing (Expectation)
import RandomGif
import Test exposing (..)
import Test.Http


program : TestContext RandomGif.Model RandomGif.Msg
program =
    RandomGif.program
        |> startWithFlags
            { apiKey = "__API_KEY__"
            , topic = "cats"
            }


assertShownImage : String -> TestContext RandomGif.Model msg -> Expectation
assertShownImage expectedImageUrl testContext =
    testContext
        |> expectModel
            (.gifUrl >> Expect.equal expectedImageUrl)


expectOk : (a -> Expectation) -> Result x a -> Expectation
expectOk check result =
    case result of
        Ok a ->
            check a

        Err _ ->
            Expect.fail ("Expected (Ok _), but got: " ++ toString result)


all : Test
all =
    describe "RandomGif"
        [ test "sets initial topic" <|
            \() ->
                program
                    |> expectModel
                        (.topic >> Expect.equal "cats")
        , test "sets initial loading image" <|
            \() ->
                program
                    |> assertShownImage "/favicon.ico"
        , test "makes initial API request" <|
            \() ->
                program
                    |> Test.Http.expectGet "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats"
        , test "shows the new image on API success" <|
            \() ->
                program
                    |> Test.Http.resolveGet
                        "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats"
                        """{"data":{"image_url":"http://giphy.com/cat2000.gif"}}"""
                    |> assertShownImage "http://giphy.com/cat2000.gif"
        , test "shows the loading image on API failure" <|
            \() ->
                program
                    |> Test.Http.rejectGet
                        "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats"
                        (Test.Http.badStatus 403)
                    |> assertShownImage "/favicon.ico"
        , test "pressing the button makes a new API request" <|
            \() ->
                program
                    |> Test.Http.resolveGet
                        "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats"
                        """{"data":{"image_url":"http://giphy.com/cat2000.gif"}}"""
                    |> update RandomGif.RequestMore
                    |> Test.Http.expectGet "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats"
        ]
