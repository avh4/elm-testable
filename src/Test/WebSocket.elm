module Test.WebSocket exposing (acceptConnection, acceptMessage)

import DefaultDict
import Dict
import Fifo
import TestContextInternal as Internal exposing (TestContext(..))
import Testable.Task exposing (ProcessId(..))


acceptConnection : String -> TestContext msg model -> TestContext msg model
acceptConnection socketUrl =
    Internal.withContext <|
        \context ->
            case Dict.get socketUrl context.pendingWebSocketConnections of
                Nothing ->
                    -- TODO: show list of pending connections
                    Internal.error context ("Expected a websocket connection to " ++ socketUrl ++ ", but none was made")

                Just next ->
                    TestContext context
                        |> Internal.processTask
                            (ProcessId -5)
                            (next <| Ok ())
                        |> Internal.drainWorkQueue


acceptMessage : String -> String -> TestContext msg model -> TestContext msg model
acceptMessage socketUrl expectedMessage =
    Internal.withContext <|
        \context ->
            case
                DefaultDict.get socketUrl context.pendingWebSocketMessages
                    |> Fifo.remove
            of
                ( Nothing, _ ) ->
                    Internal.error context ("Expected a websocket message sent to " ++ socketUrl ++ ", but none were sent")

                ( Just first, rest ) ->
                    if first == expectedMessage then
                        TestContext
                            { context
                                | pendingWebSocketMessages =
                                    context.pendingWebSocketMessages
                                        |> DefaultDict.insert socketUrl rest
                            }
                    else
                        Internal.error context ("Expected the websocket message " ++ toString expectedMessage ++ " to be sent to " ++ socketUrl ++ ", but " ++ toString first ++ " was sent")
