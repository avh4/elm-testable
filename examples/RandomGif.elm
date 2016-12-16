module RandomGif exposing (..)

-- From section 5 of the Elm Architecture Tutorial https://github.com/evancz/elm-architecture-tutorial#example-5-random-gif-viewer

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Decode as Json
import Http


-- MODEL


type alias Model =
    { apiKey : String
    , topic : String
    , gifUrl : String
    }


init : String -> String -> ( Model, Cmd Msg )
init apiKey topic =
    ( Model apiKey topic "/favicon.ico"
    , getRandomGif apiKey topic
    )



-- UPDATE


type Msg
    = RequestMore
    | NewGif (Maybe String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RequestMore ->
            ( model, getRandomGif model.apiKey model.topic )

        NewGif maybeUrl ->
            ( Model model.apiKey model.topic (Maybe.withDefault model.gifUrl maybeUrl)
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    div [ style [ ( "width", "200px" ) ] ]
        [ h2 [ headerStyle ] [ text model.topic ]
        , div [ imgStyle model.gifUrl ] []
        , button [ onClick RequestMore ] [ text "More Please!" ]
        ]


headerStyle : Attribute Msg
headerStyle =
    style
        [ ( "width", "200px" )
        , ( "text-align", "center" )
        ]


imgStyle : String -> Attribute Msg
imgStyle url =
    style
        [ ( "display", "inline-block" )
        , ( "width", "200px" )
        , ( "height", "200px" )
        , ( "background-position", "center center" )
        , ( "background-size", "cover" )
        , ( "background-image", ("url('" ++ url ++ "')") )
        ]



-- EFFECTS


getRandomGif : String -> String -> Cmd Msg
getRandomGif apiKey topic =
    Http.get (randomUrl apiKey topic) decodeUrl
        |> Http.send (Result.toMaybe >> NewGif)


randomUrl : String -> String -> String
randomUrl apiKey topic =
    "https://api.giphy.com/v1/gifs/random?"
        ++ String.join "&"
            [ "api_key=" ++ apiKey
            , "tag=" ++ topic
            ]


decodeUrl : Json.Decoder String
decodeUrl =
    Json.at [ "data", "image_url" ] Json.string
