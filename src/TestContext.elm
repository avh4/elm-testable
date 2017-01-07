module TestContext
    exposing
        ( TestContext
        , start
        , startWithMockTask
        , model
        , update
        , expectMockTask
        , resolveMockTask
        , send
        , expectCmd
        , expectHttpRequest
        )

import Native.TestContext
import Expect
import Json.Encode
import Dict exposing (Dict)
import Testable.Task exposing (fromPlatformTask, Task(..))
import Mapper exposing (Mapper)


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


type alias TestContext model msg =
    MockContext Never (Result Never Never) model msg


type MockContext mockLabel mockValue model msg
    = TestContext
        { program : TestableProgram model msg
        , model : model
        , pendingCmds : List (TestableCmd msg)
        , pendingMockTasks : Dict String (Mapper (Task msg msg))
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


start : Program flags model msg -> TestContext model msg
start realProgram =
    startWithMockTask (always realProgram)


startWithMockTask : ((mockLabel -> Platform.Task x a) -> Program flags model msg) -> MockContext mockLabel (Result x a) model msg
startWithMockTask getProgram =
    let
        program =
            getProgram (\label -> Native.TestContext.mockTask (toString label))
                |> extractProgram "<TestContext fake module>"
    in
        TestContext
            { program = program
            , model = Tuple.first program.init
            , pendingCmds = []
            , pendingMockTasks = Dict.empty
            , pendingHttpRequests = Dict.empty
            }
            |> processCmds (Tuple.second program.init)


processCmds : Cmd msg -> MockContext mockLabel mockValue model msg -> MockContext mockLabel mockValue model msg
processCmds cmds context =
    List.foldl processCmd context (extractCmds <| cmds)


processCmd : TestableCmd msg -> MockContext mockLabel mockValue model msg -> MockContext mockLabel mockValue model msg
processCmd cmd (TestContext context) =
    case cmd of
        Port home value ->
            TestContext { context | pendingCmds = context.pendingCmds ++ [ cmd ] }

        Task task ->
            processTask (fromPlatformTask task) (TestContext context)


processTask : Task msg msg -> MockContext mockLabel mockValue model msg -> MockContext mockLabel mockValue model msg
processTask task (TestContext context) =
    case task of
        Success msg ->
            TestContext context
                |> update msg

        Failure msg ->
            -- (TestContext context)
            --     |> update msg
            Debug.crash ("TODO: commented code above is not tested")

        MockTask label mapper ->
            TestContext
                { context
                    | pendingMockTasks =
                        context.pendingMockTasks
                            |> Dict.insert label mapper
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
                                task
                }


model : MockContext mockLabel mockValue model msg -> model
model (TestContext context) =
    context.model


update : msg -> MockContext mockLabel mockValue model msg -> MockContext mockLabel mockValue model msg
update msg (TestContext context) =
    let
        ( newModel, newCmds ) =
            context.program.update msg context.model
    in
        TestContext { context | model = newModel }
            |> processCmds newCmds


hasPendingMockTask : String -> MockContext mockLabel mockValue model msg -> Bool
hasPendingMockTask label (TestContext context) =
    Dict.member label context.pendingMockTasks


expectMockTask : mockLabel -> MockContext mockLabel mockValue model msg -> Expect.Expectation
expectMockTask label (TestContext context) =
    if hasPendingMockTask (toString label) (TestContext context) then
        Expect.pass
    else
        [ if Dict.isEmpty context.pendingMockTasks then
            "pending mock tasks (none were initiated)"
          else
            Dict.keys context.pendingMockTasks
                |> List.sort
                |> List.map ((++) "    - mockTask ")
                |> String.join "\n"
                |> ((++) "pending mock tasks:\n")
        , "╷"
        , "│ to include (TestContext.expectMockTask)"
        , "╵"
        , "mockTask " ++ (toString label)
        ]
            |> String.join "\n"
            |> Expect.fail


resolveMockTask : mockLabel -> mockValue -> MockContext mockLabel mockValue model msg -> Result String (MockContext mockLabel mockValue model msg)
resolveMockTask label result (TestContext context) =
    case Dict.get (toString label) context.pendingMockTasks of
        Nothing ->
            Err ("No mockTask matches: " ++ toString label)

        Just mapper ->
            Mapper.apply mapper result
                |> Result.map (\next -> processTask next (TestContext context))


send :
    ((value -> msg) -> Sub msg)
    -> value
    -> MockContext mockLabel mockValue model msg
    -> Result String (MockContext mockLabel mockValue model msg)
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
                Mapper.apply mapper value
                    |> Result.map (\msg -> update msg (TestContext context))


pendingCmds : MockContext mockLabel mockValue model msg -> List (TestableCmd msg)
pendingCmds (TestContext context) =
    context.pendingCmds


{-|
If `cmd` is a batch, then this will return True only if all Cmds in the batch
are pending.
-}
hasPendingCmd : Cmd msg -> MockContext mockLabel mockValue model msg -> Bool
hasPendingCmd cmd (TestContext context) =
    let
        testableCmd =
            extractCmds cmd
    in
        List.all (\c -> List.member c context.pendingCmds) testableCmd


expectCmd : Cmd msg -> MockContext mockLabel mockValue model msg -> Expect.Expectation
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


expectHttpRequest : String -> String -> MockContext mockLabel mockValue model msg -> Expect.Expectation
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
