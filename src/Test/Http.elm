module Test.Http
    exposing
        ( expectRequest
        , expectGet
        , resolveRequest
        , resolveGet
        )

import Dict exposing (Dict)
import Expect exposing (Expectation)
import Http
import Testable.Task exposing (fromPlatformTask, Task(..), ProcessId(..))
import TestContextInternal as Internal exposing (TestContext(..))


type alias RequestMatcher =
    { method : String
    , url : String
    , requiredHeaders : List Http.Header
    , requiredBody : Maybe String
    }


expectGet : String -> TestContext model msg -> Expectation
expectGet url =
    expectRequest
        { method = "GET"
        , url = url
        , requiredHeaders = []
        , requiredBody = Nothing
        }


expectRequest : RequestMatcher -> TestContext model msg -> Expectation
expectRequest { method, url } =
    Internal.expect identity <|
        \context ->
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


resolveGet : String -> String -> TestContext model msg -> TestContext model msg
resolveGet url =
    resolveRequest
        { method = "GET"
        , url = url
        , requiredHeaders = []
        , requiredBody = Nothing
        }


resolveRequest : RequestMatcher -> String -> TestContext model msg -> TestContext model msg
resolveRequest { method, url } responseBody =
    Internal.withContext <|
        \context ->
            case Dict.get ( method, url ) context.pendingHttpRequests of
                Just next ->
                    -- TODO: need to drain the work queue
                    TestContext
                        { context
                            | pendingHttpRequests =
                                Dict.remove ( method, url )
                                    context.pendingHttpRequests
                        }
                        |> Internal.processTask (ProcessId -4)
                            (next <|
                                { url = "TODO: not implemented yet"
                                , status = { code = 200, message = "OK" }
                                , headers = Dict.empty -- TODO
                                , body = responseBody
                                }
                            )

                Nothing ->
                    Internal.error context
                        ("No HTTP request was made matching: " ++ method ++ " " ++ url)
