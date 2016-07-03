port module Spelling exposing (..)

-- From Elm Guide on JavaScript and Ports http://guide.elm-lang.org/interop/javascript.html

import Html exposing (..)
import Html.Events exposing (..)
import String
import Testable.Cmd


-- MODEL


type alias Model =
    { word : String
    , suggestions : List String
    }


init : ( Model, Testable.Cmd.Cmd Msg )
init =
    ( Model "" [], Testable.Cmd.none )



-- UPDATE


type Msg
    = Change String
    | Check
    | Suggest (List String)


port check : String -> Cmd msg


update : Msg -> Model -> ( Model, Testable.Cmd.Cmd Msg )
update action model =
    case action of
        Change newWord ->
            ( Model newWord [], Testable.Cmd.none )

        Check ->
            ( model, Testable.Cmd.wrap <| check model.word )

        Suggest newSuggestions ->
            ( Model model.word newSuggestions, Testable.Cmd.none )



-- SUBSCRIPTIONS


port suggestions : (List String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    suggestions Suggest



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ input [ onInput Change ] []
        , button [ onClick Check ] [ text "Check" ]
        , div [] [ text (String.join ", " model.suggestions) ]
        ]
