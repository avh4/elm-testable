module Testable.NavigationTests exposing (..)

import Expect
import Navigation
import Test exposing (..)
import Testable.Navigation exposing (..)


initialLocation : Navigation.Location
initialLocation =
    getLocation "https://elm.testable/foo"


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
        ]
