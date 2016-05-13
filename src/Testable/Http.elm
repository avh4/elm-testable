module Testable.Http exposing (url, getString, get, post, Error, empty, string, Request, getRequest, Response, RawError, ok, serverError)

{-|
`Testable.Http` is a replacement for the standard `Http` module.  You can use it
to create components that can be tested with `Testable.TestContext`.

# Helpers
@docs getRequest, ok, serverError

# Encoding and Decoding
@docs url

# Fetch Strings and JSON
@docs getString, get, post, Error

# Body Values
@docs empty, string

# Arbitrary Requests
@docs Request

# Responses
@docs Response, RawError
-}

import Dict
import Http
import Json.Decode as Decode exposing (Decoder)
import Testable.Task as Task exposing (Task)
import Testable.Internal as Internal


-- Encoding and Decoding


{-| Create a properly encoded URL with a [query string][qs]. The first argument is
the portion of the URL before the query string, which is assumed to be
properly encoded already. The second argument is a list of all the
key/value pairs needed for the query string. Both the keys and values
will be appropriately encoded, so they can contain spaces, ampersands, etc.

[qs]: http://en.wikipedia.org/wiki/Query_string

    url "http://example.com/users" [ ("name", "john doe"), ("age", "30") ]
    -- http://example.com/users?name=john+doe&age=30
-}
url : String -> List ( String, String ) -> String
url =
    Http.url



-- Fetch Strings and JSON


rawErrorError : RawError -> Error
rawErrorError rawError =
    case rawError of
        Http.RawTimeout ->
            Http.Timeout

        Http.RawNetworkError ->
            Http.NetworkError


{-| Send a GET request to the given URL. You will get the entire response as a
string.

    hats : Task Error String
    hats =
        getString "http://example.com/hat-categories.markdown"
-}
getString : String -> Task Error String
getString url =
    let
        decodeResponse response =
            case response.value of
                Http.Text responseBody ->
                    Ok responseBody

                Http.Blob _ ->
                    Err <| Http.UnexpectedPayload "Not Implemented: Decoding of Http.Blob response body"
    in
        Internal.HttpTask (getRequest url)
            (Result.formatError rawErrorError
                >> (flip Result.andThen) decodeResponse
                >> Internal.resultFromResult
            )


{-| Send a GET request to the given URL. You also specify how to decode the
response.

    import Json.Decode (list, string)

    hats : Task Error (List String)
    hats =
        get (list string) "http://example.com/hat-categories.json"
-}
get : Decoder value -> String -> Task Error value
get decoder url =
    let
        decodeResponse response =
            case response.value of
                Http.Text responseBody ->
                    Decode.decodeString decoder responseBody
                        |> Result.formatError Http.UnexpectedPayload

                Http.Blob _ ->
                    Err <| Http.UnexpectedPayload "Not Implemented: Decoding of Http.Blob response body"
    in
        Internal.HttpTask (getRequest url)
            (Result.formatError rawErrorError
                >> (flip Result.andThen) decodeResponse
                >> Internal.resultFromResult
            )


{-| Send a POST request to the given URL, carrying the given body. You also
specify how to decode the response with [a JSON decoder][json].

[json]: http://package.elm-lang.org/packages/elm-lang/core/latest/Json-Decode#Decoder

    import Json.Decode (list, string)

    hats : Task Error (List String)
    hats =
        post (list string) "http://example.com/hat-categories.json" empty
-}
post : Decoder value -> String -> Body -> Task Error value
post decoder url requestBody =
    let
        decodeResponse response =
            case response.value of
                Http.Text responseBody ->
                    Decode.decodeString decoder responseBody
                        |> Result.formatError Http.UnexpectedPayload

                Http.Blob _ ->
                    Err <| Http.UnexpectedPayload "Not Implemented: Decoding of Http.Blob response body"
    in
        Internal.HttpTask
            { verb = "POST"
            , headers = []
            , url = url
            , body = requestBody
            }
            (Result.formatError rawErrorError
                >> (flip Result.andThen) decodeResponse
                >> Internal.resultFromResult
            )


{-| The kinds of errors you typically want in practice. When you get a
response but its status is not in the 200 range, it will trigger a
`BadResponse`. When you try to decode JSON but something goes wrong,
you will get an `UnexpectedPayload`.
-}
type alias Error =
    Http.Error



-- Body Values


{-| An opaque type representing the body of your HTTP message. With GET
requests this is empty, but in other cases it may be a string or blob.
-}
type alias Body =
    Http.Body


{-| An empty request body, no value will be sent along.
-}
empty : Body
empty =
    Http.empty


{-| Provide a string as the body of the request. Useful if you need to send
JSON data to a server that does not belong in the URL.

    import Json.Decode as JS

    coolestHats : Task Error (List String)
    coolestHats =
        post
            (JS.list JS.string)
            "http://example.com/hats"
            (string """{ "sortBy": "coolness", "take": 10 }""")
-}
string : String -> Body
string =
    Http.string



-- Arbitrary Requests


{-| Fully specify the request you want to send. For example, if you want to
send a request between domains (CORS request) you will need to specify some
headers manually.

    corsPost : Request
    corsPost =
        { verb = "POST"
        , headers =
            [ ("Origin", "http://elm-lang.org")
            , ("Access-Control-Request-Method", "POST")
            , ("Access-Control-Request-Headers", "X-Custom-Header")
            ]
        , url = "http://example.com/hats"
        , body = empty
        }
-}
type alias Request =
    Http.Request


{-| A convenient way to make a `Request` corresponding to the request made by `get`
-}
getRequest : String -> Request
getRequest url =
    { verb = "GET"
    , headers = []
    , url = url
    , body = Http.empty
    }



-- Responses


{-| All the details of the response. There are many weird facts about
responses which include:

  * The `status` may be 0 in the case that you load something from `file://`
  * You cannot handle redirects yourself, they will all be followed
    automatically. If you want to know if you have gone through one or more
    redirect, the `url` field will let you know who sent you the response, so
    you will know if it does not match the URL you requested.
  * You are allowed to have duplicate headers, and their values will be
    combined into a single comma-separated string.

We have left these underlying facts about `XMLHttpRequest` as is because one
goal of this library is to give a low-level enough API that others can build
whatever helpful behavior they want on top of it.
-}
type alias Response =
    Http.Response


{-| The things that count as errors at the lowest level. Technically, getting
a response back with status 404 is a &ldquo;successful&rdquo; response in that
you actually got all the information you asked for.

The `fromJson` function and `Error` type provide higher-level errors, but the
point of `RawError` is to allow you to define higher-level errors however you
want.
-}
type alias RawError =
    Http.RawError


{-| A convenient way to create a 200 OK repsonse
-}
ok : String -> Result RawError Response
ok responseBody =
    Ok
        { status = 200
        , statusText = "OK"
        , headers = Dict.empty
        , url = "<< Not Implemented >>"
        , value = Http.Text responseBody
        }


{-| A convenient way to create a response representing a 500 error
-}
serverError : Result RawError Response
serverError =
    Ok
        { status = 500
        , statusText = "Internal Server Error"
        , headers = Dict.empty
        , url = "<< Not Implemented >>"
        , value = Http.Text ""
        }
