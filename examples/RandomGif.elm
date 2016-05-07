module RandomGif exposing (..)

-- From section 5 of the Elm Architecture Tutorial https://github.com/evancz/elm-architecture-tutorial#example-5-random-gif-viewer

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Decode as Json
import Testable.Cmd
import Testable.Http as Http
import Testable.Task as Task


-- MODEL


type alias Model =
  { apiKey : String
  , topic : String
  , gifUrl : String
  }


init : String -> String -> ( Model, Testable.Cmd.Cmd Action )
init apiKey topic =
  ( Model apiKey topic "/favicon.ico"
  , getRandomGif apiKey topic
  )



-- UPDATE


type Action
  = RequestMore
  | NewGif (Maybe String)


update : Action -> Model -> ( Model, Testable.Cmd.Cmd Action )
update action model =
  case action of
    RequestMore ->
      ( model, getRandomGif model.apiKey model.topic )

    NewGif maybeUrl ->
      ( Model model.apiKey model.topic (Maybe.withDefault model.gifUrl maybeUrl)
      , Testable.Cmd.none
      )



-- VIEW


(=>) =
  (,)


view : Model -> Html Action
view model =
  div
    [ style [ "width" => "200px" ] ]
    [ h2 [ headerStyle ] [ text model.topic ]
    , div [ imgStyle model.gifUrl ] []
    , button [ onClick RequestMore ] [ text "More Please!" ]
    ]


headerStyle : Attribute Action
headerStyle =
  style
    [ "width" => "200px"
    , "text-align" => "center"
    ]


imgStyle : String -> Attribute Action
imgStyle url =
  style
    [ "display" => "inline-block"
    , "width" => "200px"
    , "height" => "200px"
    , "background-position" => "center center"
    , "background-size" => "cover"
    , "background-image" => ("url('" ++ url ++ "')")
    ]



-- EFFECTS


getRandomGif : String -> String -> Testable.Cmd.Cmd Action
getRandomGif apiKey topic =
  Http.get decodeUrl (randomUrl apiKey topic)
    |> Task.perform
        (always Nothing >> NewGif)
        (Just >> NewGif)


randomUrl : String -> String -> String
randomUrl apiKey topic =
  Http.url
    "https://api.giphy.com/v1/gifs/random"
    [ "api_key" => apiKey
    , "tag" => topic
    ]


decodeUrl : Json.Decoder String
decodeUrl =
  Json.at [ "data", "image_url" ] Json.string
