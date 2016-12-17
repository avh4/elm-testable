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
import Json.Encode


type alias TestableProgram model msg =
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    }


type TestableCmd msg
    = Task (Platform.Task Never msg)
    | Port String Json.Encode.Value


type TestContext model msg
    = TestContext
        { program : TestableProgram model msg
        , model : model
        , pendingCmds : List (TestableCmd msg)
        }


type Error
    = NothingYet__


extractProgram : String -> Program flags model msg -> TestableProgram model msg
extractProgram moduleName =
    Native.TestContext.extractProgram moduleName


extractCmds : Cmd msg -> List (TestableCmd msg)
extractCmds =
    Native.TestContext.extractCmds


performTask : Platform.Task x a -> Result x a
performTask =
    Native.TestContext.performTask


start : Program flags model msg -> TestContext model msg
start realProgram =
    let
        program =
            extractProgram "<TestContext fake module>" realProgram
    in
        TestContext
            { program = program
            , model = Tuple.first program.init
            , pendingCmds = []
            }
            |> processCmds (Tuple.second program.init)


processCmds : Cmd msg -> TestContext model msg -> TestContext model msg
processCmds cmds context =
    List.foldl processCmd context (extractCmds <| cmds)


processCmd : TestableCmd msg -> TestContext model msg -> TestContext model msg
processCmd cmd (TestContext context) =
    case cmd of
        Port home value ->
            TestContext { context | pendingCmds = context.pendingCmds ++ [ cmd ] }

        Task task ->
            case performTask task of
                Ok msg ->
                    (TestContext context)
                        |> update msg

                Err never ->
                    Debug.crash ("Got a Never value from a task: " ++ toString never)


model : TestContext model msg -> Result (List Error) model
model (TestContext context) =
    Ok context.model


update : msg -> TestContext model msg -> TestContext model msg
update msg (TestContext context) =
    let
        ( newModel, newCmds ) =
            context.program.update msg context.model
    in
        TestContext { context | model = newModel }
            |> processCmds newCmds


pendingCmds : TestContext model msg -> List (TestableCmd msg)
pendingCmds (TestContext context) =
    context.pendingCmds


{-|
If `cmd` is a batch, then this will return True only if all Cmds in the batch
are pending.
-}
hasPendingCmd : Cmd msg -> TestContext model msg -> Bool
hasPendingCmd cmd (TestContext context) =
    let
        testableCmd =
            extractCmds cmd
    in
        List.all (\c -> List.member c context.pendingCmds) testableCmd


expectCmd : Cmd msg -> TestContext model msg -> Expect.Expectation
expectCmd expected (TestContext context) =
    if hasPendingCmd expected (TestContext context) then
        Expect.pass
    else
        [ toString <| context.pendingCmds
        , "╷"
        , "│ TestContext.expectCmd"
        , "╵"
        , toString <| extractCmds expected
        ]
            |> String.join "\n"
            |> Expect.fail
