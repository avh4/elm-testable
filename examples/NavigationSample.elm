module NavigationSample exposing (program)

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (..)
import Navigation


program : Program Never Model Msg
program =
    Navigation.program UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { history : List Navigation.Location
    }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( Model [ location ]
    , Cmd.none
    )



-- UPDATE


type Msg
    = UrlChange Navigation.Location
    | Go String



{- We are just storing the location in our history in this example, but
   normally, you would use a package like evancz/url-parser to parse the path
   or hash into nicely structured Elm values.
       <http://package.elm-lang.org/packages/evancz/url-parser/latest>
-}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            ( { model | history = location :: model.history }
            , Cmd.none
            )

        Go path ->
            ( model, Navigation.newUrl path )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Pages" ]
        , ul [] (List.map viewLink [ "bears", "cats", "dogs", "elephants", "fish" ])
        , h1 [] [ text "History" ]
        , ul [ class "history" ] (List.map viewLocation model.history)
        ]


viewLink : String -> Html Msg
viewLink name =
    li [] [ button [ class name, onClick (Go <| "#" ++ name) ] [ text name ] ]


viewLocation : Navigation.Location -> Html msg
viewLocation location =
    li [] [ text (location.pathname ++ location.hash) ]
