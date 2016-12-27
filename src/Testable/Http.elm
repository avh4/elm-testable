module Testable.Http exposing (getString, get, post, Error, emptyBody, Request, Settings, send, defaultSettings, getRequest, Response, ok, serverError)

{-|
`Testable.Http` is a replacement for the standard `Http` module.  You can use it
to create components that can be tested with `Testable.TestContext`.

# Fetch Strings and JSON
@docs getString, get, post, Error

# Body Values
@docs emptyBody

# Arbitrary Requests
@docs send, Request, Settings, defaultSettings

# Responses
@docs Response, Error

# Helpers
@docs getRequest, ok, serverError
-}

import Dict
import Http
import Json.Decode as Decode exposing (Decoder)
import Testable.Internal as Internal
import Testable.Task as Task


-- Fetch Strings and JSON


{-| Send a GET request to the given URL. You will get the entire response as a
string.

    hats : Task Error String
    hats =
        getString "http://example.com/hat-categories.markdown"
-}
getString : String -> Request String
getString url =
    let
        decodeResponse response =
            Ok response.body
    in
        Internal.HttpRequest
            (getRequest url)
            (decodeResponse >> Internal.resultFromResult)


{-| Send a GET request to the given URL. You also specify how to decode the
response.

    import Json.Decode (list, string)

    hats : Task Error (List String)
    hats =
        get (list string) "http://example.com/hat-categories.json"
-}
get : String -> Decoder value -> Request value
get url decoder =
    let
        decodeResponse response =
            Decode.decodeString decoder response.body
                |> Result.mapError (\error -> Http.BadPayload error response)
    in
        Internal.HttpRequest
            (getRequest url)
            (decodeResponse >> Internal.resultFromResult)


{-| Send a POST request to the given URL, carrying the given body. You also
specify how to decode the response with [a JSON decoder][json].

[json]: http://package.elm-lang.org/packages/elm-lang/core/latest/Json-Decode#Decoder

    import Json.Decode (list, string)

    hats : Task Error (List String)
    hats =
        post (list string) "http://example.com/hat-categories.json" empty
-}
post : String -> Body -> Decoder a -> Request a
post url body decoder =
    let
        decodeResponse response =
            Decode.decodeString decoder response.body
                |> Result.mapError (\error -> Http.BadPayload error response)
    in
        Internal.HttpRequest
            { defaultSettings
                | url = url
                , method = "POST"
                , body = body
            }
            (decodeResponse >> Internal.resultFromResult)


{-| A Request can fail in a couple ways:

- BadUrl means you did not provide a valid URL.
- Timeout means it took too long to get a response.
- NetworkError means the user turned off their wifi, went in a cave, etc.
- BadStatus means you got a response back, but the status code indicates failure.
- BadPayload means you got a response back with a nice status code, but the body of the response was something unexpected. The String in this case is a debugging message that explains what went wrong with your JSON decoder or whatever.
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
emptyBody : Body
emptyBody =
    Http.emptyBody



-- Arbitrary Requests


{-| Send a request exactly how you want it. The Settings argument lets you
configure things like timeouts and progress monitoring. The Request argument
defines all the information that will actually be sent along to a server.
-}
send : (Result Error a -> msg) -> Request a -> Internal.Cmd msg
send resultToMessage request =
    Task.attempt resultToMessage (toTask request)


{-| Convert a `Request` into a `Task`. This is only really useful if you want
to chain together a bunch of requests (or any other tasks) in a single command.
-}
toTask : Request a -> Internal.Task Error a
toTask (Internal.HttpRequest settings onSuccess) =
    Internal.HttpTask settings (Err >> Internal.resultFromResult) onSuccess


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
type alias Request a =
    Internal.Request a


{-| Configure your request if you need specific behavior.
  * `timeout` lets you specify how long you are willing to wait for a response
    before giving up. By default it is 0 which means &ldquo;never give
    up!&rdquo;
  * `onStart` and `onProgress` allow you to monitor progress. This is useful
    if you want to show a progress bar when uploading a large amount of data.
  * `desiredResponseType` lets you override the MIME type of the response, so
    you can influence what kind of `Value` you get in the `Response`.
-}
type alias Settings =
    Internal.Settings


{-| The default settings used by `get` and `post`.
    { timeout = 0
    , onStart = Nothing
    , onProgress = Nothing
    , desiredResponseType = Nothing
    , withCredentials = False
    }
-}
defaultSettings : Settings
defaultSettings =
    { method = "GET"
    , headers = []
    , body = Http.emptyBody
    , timeout = Nothing
    , url = ""
    , withCredentials = False
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
type alias Response a =
    Http.Response a



-- Helpers


{-| A convenient way to make a `Request` corresponding to the request made by `get`
-}
getRequest : String -> Internal.Settings
getRequest url =
    { defaultSettings | url = url }


{-| A convenient way to create a 200 OK repsonse
-}
ok : String -> Result Error (Response String)
ok responseBody =
    Ok
        { url = "<< Not Implemented >>"
        , status = { code = 200, message = "OK" }
        , headers = Dict.empty
        , body = responseBody
        }


{-| A convenient way to create a response representing a 500 error
-}
serverError : Result Error (Response String)
serverError =
    Ok
        { url = "<< Not Implemented >>"
        , status = { code = 500, message = "Internal Server Error" }
        , headers = Dict.empty
        , body = ""
        }
