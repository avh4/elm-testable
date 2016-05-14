module RandomGifTests exposing (..)

import ElmTest exposing (..)
import Testable.TestContext exposing (..)
import Testable.Http as Http
import RandomGif


catsComponent =
    { init = RandomGif.init "__API_KEY__" "cats"
    , update = RandomGif.update
    }


assertShownImage expectedImageUrl testContext =
    testContext
        |> currentModel
        |> Result.map .gifUrl
        |> assertEqual (Ok expectedImageUrl)


all : Test
all =
    suite "RandomGif"
        [ catsComponent
            |> startForTest
            |> currentModel
            |> Result.map .topic
            |> assertEqual (Ok "cats")
            |> test "sets initial topic"
        , catsComponent
            |> startForTest
            |> assertShownImage "/favicon.ico"
            |> test "sets initial loading image"
        , catsComponent
            |> startForTest
            |> assertHttpRequest (Http.getRequest "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats")
            |> test "makes initial API request"
        , catsComponent
            |> startForTest
            |> resolveHttpRequest (Http.getRequest "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats")
                (Http.ok """{"data":{"image_url":"http://giphy.com/cat2000.gif"}}""")
            |> assertShownImage "http://giphy.com/cat2000.gif"
            |> test "shows the new image on API success"
        , catsComponent
            |> startForTest
            |> resolveHttpRequest (Http.getRequest "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats")
                (Http.serverError)
            |> assertShownImage "/favicon.ico"
            |> test "shows the loading image on API failure"
        , catsComponent
            |> startForTest
            |> resolveHttpRequest (Http.getRequest "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats")
                (Http.ok """{"data":{"image_url":"http://giphy.com/cat2000.gif"}}""")
            |> update RandomGif.RequestMore
            |> assertHttpRequest (Http.getRequest "https://api.giphy.com/v1/gifs/random?api_key=__API_KEY__&tag=cats")
            |> test "pressing the button makes a new API request"
        ]
