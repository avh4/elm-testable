module TestContext
    exposing
        ( TestContext
        , start
        , model
        , update
        , mockTask
        , expectMockTask
        , send
        , expectCmd
        , expectHttpRequest
        )

import Native.TestContext
import Expect
import Json.Encode
import Dict exposing (Dict)
import Testable.Task exposing (fromPlatformTask, Task(..))
import Set exposing (Set)


type alias TestableProgram model msg =
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    }


type TestableCmd msg
    = Task (Platform.Task msg msg)
    | Port String Json.Encode.Value


type TestableSub msg
    = PortSub String (Mapper msg)


type Mapper msg
    = Mapper_Native_


type TestContext model msg
    = TestContext
        { program : TestableProgram model msg
        , model : model
        , pendingCmds : List (TestableCmd msg)
        , pendingMockTasks : Set String
        , pendingHttpRequests : Dict ( String, String ) (Task msg msg)
        }


extractProgram : String -> Program flags model msg -> TestableProgram model msg
extractProgram moduleName =
    Native.TestContext.extractProgram moduleName


extractCmds : Cmd msg -> List (TestableCmd msg)
extractCmds =
    Native.TestContext.extractCmds


extractSubs : Sub msg -> List (TestableSub msg)
extractSubs =
    Native.TestContext.extractSubs


extractSubPortName : ((value -> msg) -> Sub msg) -> String
extractSubPortName =
    Native.TestContext.extractSubPortName


applyMapper : Mapper msg -> value -> Result String msg
applyMapper =
    Native.TestContext.applyMapper


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
            , pendingMockTasks = Set.empty
            , pendingHttpRequests = Dict.empty
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
            case fromPlatformTask task of
                Success msg ->
                    TestContext context
                        |> update msg

                Failure msg ->
                    -- (TestContext context)
                    --     |> update msg
                    Debug.crash ("TODO: commented code above is not tested")

                MockTask tag ->
                    TestContext
                        { context
                            | pendingMockTasks = Set.insert tag context.pendingMockTasks
                        }

                SleepTask time next ->
                    -- TODO: track time
                    TestContext context

                HttpTask options next ->
                    TestContext
                        { context
                            | pendingHttpRequests =
                                context.pendingHttpRequests
                                    |> Dict.insert
                                        ( options.method, options.url )
                                        (HttpTask options next)
                        }


model : TestContext model msg -> model
model (TestContext context) =
    context.model


update : msg -> TestContext model msg -> TestContext model msg
update msg (TestContext context) =
    let
        ( newModel, newCmds ) =
            context.program.update msg context.model
    in
        TestContext { context | model = newModel }
            |> processCmds newCmds


mockTask : tag -> Platform.Task x a
mockTask tag =
    Native.TestContext.mockTask (toString tag)


hasPendingMockTask : tag -> TestContext model msg -> Bool
hasPendingMockTask tag (TestContext context) =
    Set.member (toString tag) context.pendingMockTasks


expectMockTask : tag -> TestContext model msg -> Expect.Expectation
expectMockTask expected (TestContext context) =
    if hasPendingMockTask expected (TestContext context) then
        Expect.pass
    else
        [ if Set.isEmpty context.pendingMockTasks then
            "pending mock tasks (none were initiated)"
          else
            Set.toList context.pendingMockTasks
                |> List.sort
                |> List.map ((++) "    - mockTask ")
                |> String.join "\n"
                |> ((++) "pending mock tasks:\n")
        , "╷"
        , "│ to include (TestContext.expectMockTask)"
        , "╵"
        , "mockTask " ++ (toString expected)
        ]
            |> String.join "\n"
            |> Expect.fail


send :
    ((value -> msg) -> Sub msg)
    -> value
    -> TestContext model msg
    -> Result String (TestContext model msg)
send subPort value (TestContext context) =
    let
        subs =
            context.program.subscriptions context.model
                |> extractSubs
                |> List.map (\(PortSub name mapper) -> ( name, mapper ))
                |> Dict.fromList

        portName =
            extractSubPortName subPort
    in
        case Dict.get portName subs of
            Nothing ->
                Err ("Not subscribed to port: " ++ portName)

            Just mapper ->
                applyMapper mapper value
                    |> Result.map (\msg -> update msg (TestContext context))


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
        -- TODO: nicer failure messages like expectHttpRequest
        [ toString <| context.pendingCmds
        , "╷"
        , "│ TestContext.expectCmd"
        , "╵"
        , toString <| extractCmds expected
        ]
            |> String.join "\n"
            |> Expect.fail


expectHttpRequest : String -> String -> TestContext model msg -> Expect.Expectation
expectHttpRequest method url (TestContext context) =
    if Dict.member ( method, url ) context.pendingHttpRequests then
        Expect.pass
    else
        [ if Dict.isEmpty context.pendingHttpRequests then
            "pending HTTP requests (none were made)"
          else
            Dict.keys context.pendingHttpRequests
                |> List.sortBy (\( a, b ) -> ( b, a ))
                |> List.map (\( a, b ) -> "    - " ++ a ++ " " ++ b)
                |> String.join "\n"
                |> ((++) "pending HTTP requests:\n")
        , "╷"
        , "│ to include (TestContext.expectHttpRequest)"
        , "╵"
        , method ++ " " ++ url
        ]
            |> String.join "\n"
            |> Expect.fail