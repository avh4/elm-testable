module RandomGifTests exposing (..)

import Expect
import RandomGif
import Test exposing (..)
import Testable.TestContext exposing (..)
import Testable.Http as Http


catsComponent =
    { init = RandomGif.init "cats"
    , update = RandomGif.update
    }


assertShownImage expectedImageUrl testContext =
    testContext
        |> currentModel
        |> Result.map .gifUrl
        |> Expect.equal (Ok expectedImageUrl)


all : Test
all =
    describe "RandomGif"
        [ test "sets initial topic" <|
            \() ->
                catsComponent
                    |> startForTest
                    |> currentModel
                    |> Result.map .topic
                    |> Expect.equal (Ok "cats")
        , test "sets initial loading image" <|
            \() ->
                catsComponent
                    |> startForTest
                    |> assertShownImage "/favicon.ico"
        , test "makes initial API request" <|
            \() ->
                catsComponent
                    |> startForTest
                    |> assertHttpRequest (Http.getRequest "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats")
        , test "shows the new image on API success" <|
            \() ->
                catsComponent
                    |> startForTest
                    |> resolveHttpRequest (Http.getRequest "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats")
                        (Http.ok """{"data":{"image_url":"http://giphy.com/cat2000.gif"}}""")
                    |> assertShownImage "http://giphy.com/cat2000.gif"
        , test "shows the loading image on API failure" <|
            \() ->
                catsComponent
                    |> startForTest
                    |> resolveHttpRequest (Http.getRequest "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats")
                        (Http.serverError)
                    |> assertShownImage "/favicon.ico"
        , test "pressing the button makes a new API request" <|
            \() ->
                catsComponent
                    |> startForTest
                    |> resolveHttpRequest (Http.getRequest "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats")
                        (Http.ok """{"data":{"image_url":"http://giphy.com/cat2000.gif"}}""")
                    |> update RandomGif.MorePlease
                    |> assertHttpRequest (Http.getRequest "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats")
        ]
