module SpellingTests exposing (..)

import Test exposing (..)
import Testable.TestContext exposing (..)
import Spelling


spellingComponent : Testable.TestContext.Component Spelling.Msg Spelling.Model
spellingComponent =
    { init = Spelling.init
    , update = Spelling.update
    }


all : Test
all =
    describe "Spelling"
        [ test "call suggestions check port when requested" <|
            \() ->
                spellingComponent
                    |> startForTest
                    |> update (Spelling.Change "cats")
                    |> update Spelling.Check
                    |> assertCmdCalled (Spelling.check "cats")
        ]
