module Testable.NavigationTests exposing (..)

import Expect
import Test exposing (..)
import Testable.Navigation exposing (..)


all : Test
all =
    describe "Navigation"
        [ describe "getLocation"
            [ test "parses a location correclty" <|
                \() ->
                    getLocation "https://elm.testable:3030/foo/bar?baz=qux#lorem"
                        |> Expect.equal
                            { href = "https://elm.testable:3030/foo/bar?baz=qux#lorem"
                            , host = "elm.testable"
                            , hostname = "elm.testable"
                            , protocol = "https:"
                            , origin = "https://elm.testable"
                            , port_ = "3030"
                            , pathname = "/foo/bar"
                            , search = "?baz=qux"
                            , hash = "#lorem"
                            , username = ""
                            , password = ""
                            }
            ]
        , describe "setLocation"
            [ test "replaces the path when the requested url is a root path" <|
                \() ->
                    initialLocation
                        |> setLocation "/foo"
                        |> .href
                        |> Expect.equal "https://elm.testable/foo"
            , test "only changes the last part of the path when requesting a relative url" <|
                \() ->
                    initialLocation
                        |> setLocation "/foo/bar"
                        |> setLocation "baz"
                        |> .href
                        |> Expect.equal "https://elm.testable/foo/baz"
            , test "change relative path as root for pathless href" <|
                \() ->
                    initialLocation
                        |> setLocation "foo"
                        |> .href
                        |> Expect.equal "https://elm.testable/foo"
            , test "updates the query string" <|
                \() ->
                    initialLocation
                        |> setLocation "/foo"
                        |> setLocation "?q=bar"
                        |> .href
                        |> Expect.equal "https://elm.testable/foo?q=bar"
            , test "updates the hash" <|
                \() ->
                    initialLocation
                        |> setLocation "/foo?bar#baz"
                        |> setLocation "#qux"
                        |> .href
                        |> Expect.equal "https://elm.testable/foo?bar#qux"
            , test "updates the whole path" <|
                \() ->
                    initialLocation
                        |> setLocation "http://www.google.com"
                        |> .href
                        |> Expect.equal "http://www.google.com"
            ]
        , describe "update"
            [ describe "new url"
                [ test "adds a new url to the history" <|
                    \() ->
                        init
                            |> update (New "/foo")
                            |> Expect.equal
                                ( ( 1
                                  , [ initialLocation
                                    , getLocation "https://elm.testable/foo"
                                    ]
                                  )
                                , ReturnLocation (getLocation "https://elm.testable/foo")
                                )
                , test "erases forward history" <|
                    \() ->
                        init
                            |> update (New "/foo")
                            |> thenUpdate (New "/bar")
                            |> thenUpdate (Jump -2)
                            |> thenUpdate (New "/baz")
                            |> Expect.equal
                                ( ( 1
                                  , [ initialLocation
                                    , getLocation "https://elm.testable/baz"
                                    ]
                                  )
                                , ReturnLocation (getLocation "https://elm.testable/baz")
                                )
                ]
            , describe "modify url"
                [ test "modify current location in the history" <|
                    \() ->
                        init
                            |> update (Modify "/foo")
                            |> Expect.equal
                                ( ( 0
                                  , [ getLocation "https://elm.testable/foo"
                                    ]
                                  )
                                , ReturnLocation (getLocation "https://elm.testable/foo")
                                )
                , test "does not erase forward history" <|
                    \() ->
                        init
                            |> update (New "/foo")
                            |> thenUpdate (New "/bar")
                            |> thenUpdate (Jump -1)
                            |> thenUpdate (Modify "/baz")
                            |> Expect.equal
                                ( ( 1
                                  , [ initialLocation
                                    , getLocation "https://elm.testable/baz"
                                    , getLocation "https://elm.testable/bar"
                                    ]
                                  )
                                , ReturnLocation (getLocation "https://elm.testable/baz")
                                )
                , test "does not modify to the same url, preventing infinite loop" <|
                    \() ->
                        init
                            |> update (New "/foo")
                            |> thenUpdate (Modify "/foo")
                            |> Expect.equal
                                ( ( 1
                                  , [ initialLocation
                                    , getLocation "https://elm.testable/foo"
                                    ]
                                  )
                                , NoOp
                                )
                ]
            , describe "jump in history" <|
                [ test "goes back, asking to trigger location msg" <|
                    \() ->
                        init
                            |> update (New "/foo")
                            |> thenUpdate (New "/bar")
                            |> thenUpdate (Jump -1)
                            |> Expect.equal
                                ( ( 1
                                  , [ initialLocation
                                    , getLocation "https://elm.testable/foo"
                                    , getLocation "https://elm.testable/bar"
                                    ]
                                  )
                                , TriggerLocationMsg (getLocation "https://elm.testable/foo")
                                )
                , test "goes forward, asking to trigger location msg" <|
                    \() ->
                        init
                            |> update (New "/foo")
                            |> thenUpdate (New "/bar")
                            |> thenUpdate (Jump -2)
                            |> thenUpdate (Jump 1)
                            |> Expect.equal
                                ( ( 1
                                  , [ initialLocation
                                    , getLocation "https://elm.testable/foo"
                                    , getLocation "https://elm.testable/bar"
                                    ]
                                  )
                                , TriggerLocationMsg (getLocation "https://elm.testable/foo")
                                )
                , test "has a limit to jumping back" <|
                    \() ->
                        init
                            |> update (New "/foo")
                            |> thenUpdate (Jump -100)
                            |> Expect.equal
                                ( ( 0
                                  , [ initialLocation
                                    , getLocation "https://elm.testable/foo"
                                    ]
                                  )
                                , TriggerLocationMsg initialLocation
                                )
                , test "has a limit to jumping forward" <|
                    \() ->
                        init
                            |> update (New "/foo")
                            |> thenUpdate (Jump -1)
                            |> thenUpdate (Jump 100)
                            |> Expect.equal
                                ( ( 1
                                  , [ initialLocation
                                    , getLocation "https://elm.testable/foo"
                                    ]
                                  )
                                , TriggerLocationMsg (getLocation "https://elm.testable/foo")
                                )
                ]
            ]
        ]


thenUpdate : Msg -> ( History, a ) -> ( History, ReturnMsg )
thenUpdate msg =
    Tuple.first >> update msg
