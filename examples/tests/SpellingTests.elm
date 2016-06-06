module SpellingTests exposing (..)

import ElmTest exposing (..)
import Testable.TestContext exposing (..)
import Spelling


spellingComponent : Testable.TestContext.Component Spelling.Msg Spelling.Model
spellingComponent =
    { init = Spelling.init
    , update = Spelling.update
    }


all : Test
all =
    suite "Spelling"
        [ spellingComponent
            |> startForTest
            |> update (Spelling.Change "cats")
            |> update Spelling.Check
            |> assertPortCalled (Spelling.check "cats")
            |> test "call suggestions check port when requested"
        ]
