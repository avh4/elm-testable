module Testable.Navigation exposing (..)

import List.Extra
import
    -- This "unused" import is required for the native bindings
    Native.Testable.Navigation
import Navigation exposing (Location)
import Regex exposing (HowMany(..), find, regex)


type alias History =
    ( Int, List Location )


type Msg
    = Jump Int
    | New String
    | Modify String


type ReturnMsg
    = ReturnLocation Location
    | TriggerLocationMsg Location


currentLocation : History -> Location
currentLocation ( index, history ) =
    List.Extra.getAt index history
        |> Maybe.withDefault (getLocation "")


update : Msg -> History -> ( History, ReturnMsg )
update msg ( index, history ) =
    let
        location =
            currentLocation ( index, history )
    in
    case msg of
        Jump n ->
            let
                nextIndex =
                    min (max (index + n) 0) (List.length history - 1)

                nextLocation =
                    List.Extra.getAt nextIndex history
                        |> Maybe.withDefault (getLocation "")
            in
            ( ( nextIndex, history ), TriggerLocationMsg nextLocation )

        New url ->
            let
                nextLocation =
                    setLocation url location

                modifiedHistory =
                    List.take (index + 1) history ++ [ nextLocation ]
            in
            ( ( index + 1, modifiedHistory ), ReturnLocation nextLocation )

        Modify url ->
            let
                nextLocation =
                    setLocation url location

                modifiedHistory =
                    history
                        |> List.Extra.updateIfIndex ((==) index) (always nextLocation)
            in
            ( ( index, history ), ReturnLocation nextLocation )


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

        pathname =
            Maybe.withDefault "/" (matchAt 4)
    in
    { href = href
    , host = host
    , hostname = host
    , protocol = protocol
    , origin = protocol ++ "//" ++ host
    , port_ = matchOrEmptyAt 3
    , pathname =
        if String.isEmpty pathname then
            "/"
        else
            pathname
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
