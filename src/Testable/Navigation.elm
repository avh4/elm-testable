module Testable.Navigation exposing (..)

import List.Extra
import Native.Testable.Navigation
import Navigation exposing (Location)
import Process
import Regex exposing (HowMany(..), find, regex)
import Task exposing (Task)


type alias History =
    ( Int, List Location )


type Msg
    = Jump Int
    | New String
    | Modify String


currentLocation : History -> Location
currentLocation ( index, history ) =
    List.Extra.getAt index history
        |> Maybe.withDefault (getLocation "")


update : Msg -> History -> ( History, Location )
update msg ( index, history ) =
    let
        location =
            currentLocation ( index, history )
    in
    case msg of
        Jump n ->
            let
                nextIndex =
                    index + n

                location =
                    List.Extra.getAt nextIndex history
                        |> Maybe.withDefault (getLocation "")
            in
            ( ( nextIndex, history ), location )

        New url ->
            let
                nextLocation =
                    setLocation url location
            in
            ( ( index + 1, history ++ [ nextLocation ] ), nextLocation )

        Modify url ->
            let
                nextLocation =
                    setLocation url location
            in
            ( ( index + 1, history ++ [ nextLocation ] ), nextLocation )


init : History
init =
    ( 0, [ initialLocation ] )


initialLocation : Location
initialLocation =
    getLocation "https://elm.testable/"


getLocation : String -> Navigation.Location
getLocation href =
    let
        parser =
            find All (regex "(.*?:)//(.*?):?(\\d+)?(/.*?|$)(\\?.*?|$)(#.*|$)") href

        matchAt index =
            List.head parser
                |> Maybe.andThen
                    (.submatches
                        >> List.Extra.getAt (index - 1)
                        >> Maybe.withDefault Nothing
                    )

        matchOrEmptyAt index =
            Maybe.withDefault "" (matchAt index)

        protocol =
            matchOrEmptyAt 1

        host =
            matchOrEmptyAt 2
    in
    { href = href
    , host = host
    , hostname = host
    , protocol = protocol
    , origin = protocol ++ "//" ++ host
    , port_ = matchOrEmptyAt 3
    , pathname = Maybe.withDefault "/" (matchAt 4)
    , search = matchOrEmptyAt 5
    , hash = matchOrEmptyAt 6
    , username = ""
    , password = ""
    }


setLocation : String -> Navigation.Location -> Navigation.Location
setLocation url currentLocation =
    let
        nextHref =
            if Regex.contains (regex "^/") url then
                currentLocation.origin ++ url
            else if Regex.contains (regex "^\\?") url then
                currentLocation.origin ++ currentLocation.pathname ++ url
            else if Regex.contains (regex "^#") url then
                currentLocation.origin ++ currentLocation.pathname ++ currentLocation.search ++ url
            else if Regex.contains (regex "^[A-z]+://") url then
                url
            else
                currentLocation.origin ++ Regex.replace (AtMost 1) (regex "/[^/]*$") (\_ -> "/" ++ url) currentLocation.pathname
    in
    getLocation nextHref
