module Test.Http
    exposing
        ( RequestMatcher
        , badStatus
        , expectGet
        , expectRequest
        , rejectGet
        , resolveGet
        , resolveRequest
        )

{-| Test.Http has helpers for you to mock and assert http responses


# Responses

@docs badStatus, resolveGet, rejectGet, resolveRequest


# Assertions

@docs RequestMatcher, expectGet, expectRequest

-}

import Dict exposing (Dict)
import Expect exposing (Expectation)
import Http
import TestContextInternal as Internal exposing (TestContext(..))
import Testable.Task exposing (ProcessId(..), Task(..), fromPlatformTask)


{-| A type used for asserting requests
-}
type alias RequestMatcher =
    { method : String
    , url : String
    , requiredHeaders : List Http.Header
    , requiredBody : Maybe String
    }


type alias Response =
    { url : String
    , statusCode : Int
    , headers : Dict String String
    , body : String
    }


{-| Asserts that a get was called to the right url
-}
expectGet : String -> TestContext model msg -> Expectation
expectGet url =
    expectRequest
        { method = "GET"
        , url = url
        , requiredHeaders = []
        , requiredBody = Nothing
        }


{-| Asserts that a request was made with the right method, url, headers and body
-}
expectRequest : RequestMatcher -> TestContext model msg -> Expectation
expectRequest { method, url } =
    Internal.expect "Test.Http.expectRequest" identity <|
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
                        |> (++) "pending HTTP requests:\n"
                , "╷"
                , "│ to include (Test.Http.expectRequest)"
                , "╵"
                , method ++ " " ++ url
                ]
                    |> String.join "\n"
                    |> Expect.fail


{-| Simulate a GET HTTP response
-}
resolveGet : String -> String -> TestContext model msg -> TestContext model msg
resolveGet url body =
    resolveRequest
        { method = "GET"
        , url = url
        , requiredHeaders = []
        , requiredBody = Nothing
        }
        (Ok body)


{-| A convenient way to create bad status responses
-}
badStatus : Int -> Http.Error
badStatus statusCode =
    Http.BadStatus
        { url = "TODO"
        , status =
            { code = statusCode
            , message =
                Dict.get statusCode statusMessages
                    |> Maybe.withDefault ""
            }
        , headers = Dict.empty
        , body = ""
        }


{-| Simulate a GET HTTP request that had an error
-}
rejectGet : String -> Http.Error -> TestContext model msg -> TestContext model msg
rejectGet url error =
    resolveRequest
        { method = "GET"
        , url = url
        , requiredHeaders = []
        , requiredBody = Nothing
        }
        (Err error)


{-| Simulate any kind of HTTP responses that matches the given `RequestMatcher`
-}
resolveRequest : RequestMatcher -> Result Http.Error String -> TestContext model msg -> TestContext model msg
resolveRequest { method, url } response =
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
                            (next response)

                Nothing ->
                    Internal.error context
                        ("No HTTP request was made matching: " ++ method ++ " " ++ url)


{-| Standard http status messages
-}
statusMessages : Dict Int String
statusMessages =
    Dict.fromList
        [ ( 100, "Continue" )
        , ( 101, "Switching Protocols" )
        , ( 102, "Processing" )
        , ( 200, "OK" )
        , ( 201, "Created" )
        , ( 202, "Accepted" )
        , ( 203, "Non-authoritative Information" )
        , ( 204, "No Content" )
        , ( 205, "Reset Content" )
        , ( 206, "Partial Content" )
        , ( 207, "Multi-Status" )
        , ( 208, "Already Reported" )
        , ( 226, "IM Used" )
        , ( 300, "Multiple Choices" )
        , ( 301, "Moved Permanently" )
        , ( 302, "Found" )
        , ( 303, "See Other" )
        , ( 304, "Not Modified" )
        , ( 305, "Use Proxy" )
        , ( 307, "Temporary Redirect" )
        , ( 308, "Permanent Redirect" )
        , ( 400, "Bad Request" )
        , ( 401, "Unauthorized" )
        , ( 402, "Payment Required" )
        , ( 403, "Forbidden" )
        , ( 404, "Not Found" )
        , ( 405, "Method Not Allowed" )
        , ( 406, "Not Acceptable" )
        , ( 407, "Proxy Authentication Required" )
        , ( 408, "Request Timeout" )
        , ( 409, "Conflict" )
        , ( 410, "Gone" )
        , ( 411, "Length Required" )
        , ( 412, "Precondition Failed" )
        , ( 413, "Payload Too Large" )
        , ( 414, "Request-URI Too Long" )
        , ( 415, "Unsupported Media Type" )
        , ( 416, "Requested Range Not Satisfiable" )
        , ( 417, "Expectation Failed" )
        , ( 418, "I'm a teapot" )
        , ( 421, "Misdirected Request" )
        , ( 422, "Unprocessable Entity" )
        , ( 423, "Locked" )
        , ( 424, "Failed Dependency" )
        , ( 426, "Upgrade Required" )
        , ( 428, "Precondition Required" )
        , ( 429, "Too Many Requests" )
        , ( 431, "Request Header Fields Too Large" )
        , ( 444, "Connection Closed Without Response" )
        , ( 451, "Unavailable For Legal Reasons" )
        , ( 499, "Client Closed Request" )
        , ( 500, "Internal Server Error" )
        , ( 501, "Not Implemented" )
        , ( 502, "Bad Gateway" )
        , ( 503, "Service Unavailable" )
        , ( 504, "Gateway Timeout" )
        , ( 505, "HTTP Version Not Supported" )
        , ( 506, "Variant Also Negotiates" )
        , ( 507, "Insufficient Storage" )
        , ( 508, "Loop Detected" )
        , ( 510, "Not Extended" )
        , ( 511, "Network Authentication Required" )
        , ( 599, "Network Connect Timeout Error" )
        ]
