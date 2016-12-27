module Testable.Http exposing (Request, send, Error, getString, get, post, request, Header, header, Body, emptyBody, jsonBody, stringBody, multipartBody, Part, stringPart, Response, encodeUri, decodeUri, toTask, Settings, defaultSettings, getRequest, ok, serverError)

{-| Create and send HTTP requests.

# Send Requests
@docs Request, send, Error

# GET
@docs getString, get

# POST
@docs post

# Custom Requests
@docs request

## Headers
@docs Header, header

## Request Bodies
@docs Body, emptyBody, jsonBody, stringBody, multipartBody, Part, stringPart

## Responses
@docs Response

# Low-Level
@docs encodeUri, decodeUri, toTask

# Helpers
@docs Settings, defaultSettings, getRequest, ok, serverError

-}

import Dict
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Testable.Internal as Internal
import Testable.Task as Task


-- REQUESTS


{-| Describes an HTTP request.
-}
type alias Request a =
    Internal.Request a


{-| Send a `Request`. We could get the text of “War and Peace” like this:

    import Http

    type Msg = Click | NewBook (Result Http.Error String)

    update : Msg -> Model -> Model
    update msg model =
      case msg of
        Click ->
          ( model, getWarAndPeace )

        NewBook (Ok book) ->
          ...

        NewBook (Err _) ->
          ...

    getWarAndPeace : Cmd Msg
    getWarAndPeace =
      Http.send NewBook <|
        Http.getString "https://example.com/books/war-and-peace.md"
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


{-| A Request can fail in a couple ways:

- BadUrl means you did not provide a valid URL.
- Timeout means it took too long to get a response.
- NetworkError means the user turned off their wifi, went in a cave, etc.
- BadStatus means you got a response back, but the status code indicates failure.
- BadPayload means you got a response back with a nice status code, but the body of the response was something unexpected. The String in this case is a debugging message that explains what went wrong with your JSON decoder or whatever.
-}
type alias Error =
    Http.Error



-- GET


{-| Create a `GET` request and interpret the response body as a `String`.

    import Http

    getWarAndPeace : Http.Request String
    getWarAndPeace =
      Http.getString "https://example.com/books/war-and-peace"
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


{-| Create a `GET` request and try to decode the response body from JSON to
some Elm value.

    import Http
    import Json.Decode exposing (list, string)

    getBooks : Http.Request (List String)
    getBooks =
      Http.get "https://example.com/books" (list string)

You can learn more about how JSON decoders work [here][] in the guide.

[here]: https://guide.elm-lang.org/interop/json.html
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



-- POST


{-| Create a `POST` request and try to decode the response body from JSON to
an Elm value. For example, if we want to send a POST without any data in the
request body, it would be like this:

    import Http
    import Json.Decode exposing (list, string)

    postBooks : Http.Request (List String)
    postBooks =
      Http.post "https://example.com/books" Http.emptyBody (list string)

See [`jsonBody`](#jsonBody) to learn how to have a more interesting request
body. And check out [this section][here] of the guide to learn more about
JSON decoders.

[here]: https://guide.elm-lang.org/interop/json.html

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



-- CUSTOM REQUESTS


{-| Create a custom request. For example, a custom PUT request would look like
this:

    put : String -> Body -> Request ()
    put url body =
      request
        { method = "PUT"
        , headers = []
        , url = url
        , body = body
        , expect = expectStringResponse (\_ -> Ok ())
        , timeout = Nothing
        , withCredentials = False
        }
-}
request : Settings -> Decoder a -> Request a
request settings decoder =
    let
        decodeResponse response =
            Decode.decodeString decoder response.body
                |> Result.mapError (\error -> Http.BadPayload error response)
    in
        Internal.HttpRequest settings (decodeResponse >> Internal.resultFromResult)



-- HEADERS


{-| An HTTP header for configuring requests. See a bunch of common headers
[here][].

[here]: https://en.wikipedia.org/wiki/List_of_HTTP_header_fields
-}
type alias Header =
    Http.Header


{-| Create a `Header`.

    header "If-Modified-Since" "Sat 29 Oct 1994 19:43:31 GMT"
    header "Max-Forwards" "10"
    header "X-Requested-With" "XMLHttpRequest"

**Note:** In the future, we may split this out into an `Http.Headers` module
and provide helpers for cases that are common on the client-side. If this
sounds nice to you, open an issue [here][] describing the helper you want and
why you need it.

[here]: https://github.com/elm-lang/http/issues
-}
header : String -> String -> Http.Header
header =
    Http.header



-- BODY


{-| Represents the body of a `Request`.
-}
type alias Body =
    Http.Body


{-| Create an empty body for your `Request`. This is useful for GET requests
and POST requests where you are not sending any data.
-}
emptyBody : Body
emptyBody =
    Http.emptyBody


{-| Put some JSON value in the body of your `Request`. This will automatically
add the `Content-Type: application/json` header.
-}
jsonBody : Encode.Value -> Body
jsonBody value =
    Http.stringBody "application/json" (Encode.encode 0 value)


{-| Put some string in the body of your `Request`. Defining `jsonBody` looks
like this:

    import Json.Encode as Encode

    jsonBody : Encode.Value -> Body
    jsonBody value =
      stringBody "application/json" (Encode.encode 0 value)

Notice that the first argument is a [MIME type][mime] so we know to add
`Content-Type: application/json` to our request headers. Make sure your
MIME type matches your data. Some servers are strict about this!

[mime]: https://en.wikipedia.org/wiki/Media_type
-}
stringBody : String -> String -> Body
stringBody =
    Http.stringBody


{-| Create multi-part bodies for your `Request`, automatically adding the
`Content-Type: multipart/form-data` header.
-}
multipartBody : List Part -> Body
multipartBody =
    Native.Http.multipart


{-| Contents of a multi-part body. Right now it only supports strings, but we
will support blobs and files when we get an API for them in Elm.
-}
type alias Part =
    Http.Part


{-| A named chunk of string data.

    body =
      multipartBody
        [ stringPart "user" "tom"
        , stringPart "payload" "42"
        ]
-}
stringPart : String -> String -> Part
stringPart =
    Http.stringPart



-- RESPONSES


{-| The response from a `Request`.
-}
type alias Response a =
    Http.Response a



-- LOW-LEVEL


{-| Use this to escape query parameters. Converts characters like `/` to `%2F`
so that it does not clash with normal URL

It work just like `encodeURIComponent` in JavaScript.
-}
encodeUri : String -> String
encodeUri =
    Http.encodeUri


{-| Use this to unescape query parameters. It converts things like `%2F` to
`/`. It can fail in some cases. For example, there is no way to unescape `%`
because it could never appear alone in a properly escaped string.

It works just like `decodeURIComponent` in JavaScript.
-}
decodeUri : String -> Maybe String
decodeUri =
    Http.decodeUri



-- HELPERS


{-| Specific Settings that you can send to your request when you
  want a more custom request, like with differente headers or a timeout.
-}
type alias Settings =
    Internal.Settings


{-| The default settings used by `get` and `post`. The url must be changed.
    { method = "GET"
    , headers = []
    , body = Http.emptyBody
    , timeout = Nothing
    , url = ""
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
