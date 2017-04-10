module WebsocketChat exposing (program, Msg(..))

import Html exposing (Html)
import WebSocket


type alias Model =
    { entry : String
    }


initialModel : Model
initialModel =
    { entry = ""
    }


type Msg
    = TypeMessage String
    | SendMessage


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TypeMessage text ->
            ( { model | entry = text }, Cmd.none )

        SendMessage ->
            ( model, WebSocket.send "ws://localhost:3000/chat" model.entry )


view : Model -> Html Msg
view model =
    Html.text <| toString model


program : Program Never Model Msg
program =
    Html.program
        { init = ( initialModel, Cmd.none )
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
