module RandomGif exposing (..)

--- From example 5 of the Elm Architecture Tutorial https://github.com/evancz/elm-architecture-tutorial/blob/master/examples/05-http.elm

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Testable.Http as Http
import Json.Decode as Decode
import Testable
import Testable.Cmd


main : Program Never Model Msg
main =
    Html.program
        { init = Testable.init (init "cats")
        , view = view
        , update = Testable.update update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { topic : String
    , gifUrl : String
    }


init : String -> ( Model, Testable.Cmd.Cmd Msg )
init topic =
    ( Model topic "waiting.gif"
    , getRandomGif topic
    )



-- UPDATE


type Msg
    = MorePlease
    | NewGif (Result Http.Error String)


update : Msg -> Model -> ( Model, Testable.Cmd.Cmd Msg )
update msg model =
    case msg of
        MorePlease ->
            ( model, getRandomGif model.topic )

        NewGif (Ok newUrl) ->
            ( Model model.topic newUrl, Testable.Cmd.none )

        NewGif (Err _) ->
            ( model, Testable.Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text model.topic ]
        , button [ onClick MorePlease ] [ text "More Please!" ]
        , br [] []
        , img [ src model.gifUrl ] []
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- HTTP


getRandomGif : String -> Testable.Cmd.Cmd Msg
getRandomGif topic =
    let
        url =
            "https://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC&tag=" ++ topic
    in
        Http.send NewGif (Http.get url decodeGifUrl)


decodeGifUrl : Decode.Decoder String
decodeGifUrl =
    Decode.at [ "data", "image_url" ] Decode.string
