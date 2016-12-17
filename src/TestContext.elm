module TestContext
    exposing
        ( TestContext
        , start
        , model
        , update
        , expectCmd
        )

import Native.TestContext
import Expect


type TestContext model msg
    = TestContextNativeValue


type Error
    = NothingYet__


start : Program flags model msg -> TestContext model msg
start =
    Native.TestContext.start


model : TestContext model msg -> Result (List Error) model
model =
    Native.TestContext.model


update : msg -> TestContext model msg -> TestContext model msg
update =
    Native.TestContext.update


pendingCmds : TestContext model msg -> List (Cmd msg)
pendingCmds =
    Native.TestContext.pendingCmds


hasPendingCmd : Cmd msg -> TestContext model msg -> Bool
hasPendingCmd =
    Native.TestContext.hasPendingCmd


expectCmd : Cmd msg -> TestContext model msg -> Expect.Expectation
expectCmd expected context =
    if hasPendingCmd expected context then
        Expect.pass
    else
        [ "<pending commands>"
        , "╷"
        , "│ TestContext.expectCmd"
        , "╵"
        , toString expected
        ]
            |> String.join "\n"
            |> Expect.fail
