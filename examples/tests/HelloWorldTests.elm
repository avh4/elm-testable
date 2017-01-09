module HelloWorldTests exposing (..)

import Test exposing (..)
import Testable.Cmd
import Testable.TestContext exposing (..)
import HelloWorld
import Expect exposing (Expectation)


helloWorldComponent : Testable.TestContext.Component () ()
helloWorldComponent =
    { init = ( (), Testable.Cmd.none )
    , update = (\_ _ -> ( (), Testable.Cmd.none ))
    , view = (\_ -> HelloWorld.view)
    }


all : Test
all =
    describe "HelloWorld"
        [ test "has a message for the world" <|
            \() ->
                helloWorldComponent
                    |> startForTest
                    |> assertText (Expect.equal "Hello World!")
        ]
