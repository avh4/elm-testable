module Test.Util exposing (..)

import Expect exposing (Expectation)


expectFailure : List String -> Expectation -> Expectation
expectFailure expectedMessage expectation =
    expectation
        |> Expect.getFailure
        |> expectJust
            (.message >> expectContains (String.join "\n" expectedMessage))


expectContains : String -> String -> Expectation
expectContains expected actual =
    if String.contains expected actual then
        Expect.pass
    else
        Expect.fail ("Expected " ++ toString actual ++ " to contain " ++ expected)


expectJust : (a -> Expectation) -> Maybe a -> Expectation
expectJust expectation result =
    case result of
        Nothing ->
            Expect.fail ("Expect (Ok _), but got: " ++ toString result)

        Just a ->
            expectation a


expectOk : (a -> Expectation) -> Result String a -> Expectation
expectOk expectation result =
    case result of
        Err x ->
            Expect.fail x

        Ok a ->
            expectation a
