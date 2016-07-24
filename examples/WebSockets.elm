port module WebSockets exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Events exposing (..)
import WebSocket
import Testable
import Testable.Cmd


main : Program Never
main =
    Html.program
        { init = Testable.init init
        , view = view
        , update = Testable.update update
        , subscriptions = subscriptions
        }


echoServer : String
echoServer =
    "ws://echo.websocket.org"



-- MODEL


type alias Model =
    { input : String
    , messages : List String
    }


init : ( Model, Testable.Cmd.Cmd Msg )
init =
    ( Model "" [], Testable.Cmd.none )



-- UPDATE


type Msg
    = Input String
    | Send
    | NewMessage String


update : Msg -> Model -> ( Model, Testable.Cmd.Cmd Msg )
update msg { input, messages } =
    case msg of
        Input newInput ->
            ( Model newInput messages, Testable.Cmd.none )

        Send ->
            ( Model "" messages, Testable.Cmd.wrap <| WebSocket.send echoServer input )

        NewMessage str ->
            ( Model input (str :: messages), Testable.Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen echoServer NewMessage



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ input [ onInput Input ] []
        , button [ onClick Send ] [ text "Send" ]
        , div [] (List.map viewMessage (List.reverse model.messages))
        ]


viewMessage : String -> Html msg
viewMessage msg =
    div [] [ text msg ]
