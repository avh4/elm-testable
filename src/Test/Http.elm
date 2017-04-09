module Test.Http exposing (expectRequest, resolveRequest)

import Dict exposing (Dict)
import Expect exposing (Expectation)
import Testable.Task exposing (fromPlatformTask, Task(..), ProcessId(..))
import TestContextInternal as Internal exposing (TestContext(..))


expectRequest : String -> String -> TestContext model msg -> Expectation
expectRequest method url (TestContext context) =
    if Dict.member ( method, url ) context.pendingHttpRequests then
        Expect.pass
    else
        -- TODO: use listFailure
        [ if Dict.isEmpty context.pendingHttpRequests then
            "pending HTTP requests (none were made)"
          else
            Dict.keys context.pendingHttpRequests
                |> List.sortBy (\( a, b ) -> ( b, a ))
                |> List.map (\( a, b ) -> "    - " ++ a ++ " " ++ b)
                |> String.join "\n"
                |> ((++) "pending HTTP requests:\n")
        , "╷"
        , "│ to include (Test.Http.expectRequest)"
        , "╵"
        , method ++ " " ++ url
        ]
            |> String.join "\n"
            |> Expect.fail


resolveRequest : String -> String -> String -> TestContext model msg -> Result String (TestContext model msg)
resolveRequest method url responseBody (TestContext context) =
    case Dict.get ( method, url ) context.pendingHttpRequests of
        Just next ->
            Ok <|
                -- TODO: need to drain the work queue
                Internal.processTask (ProcessId -4)
                    (next <|
                        { url = "TODO: not implemented yet"
                        , status = { code = 200, message = "OK" }
                        , headers = Dict.empty -- TODO
                        , body = responseBody
                        }
                    )
                    (TestContext
                        { context
                            | pendingHttpRequests =
                                Dict.remove ( method, url )
                                    context.pendingHttpRequests
                        }
                    )

        Nothing ->
            Err ("No HTTP request was made matching: " ++ method ++ " " ++ url)
