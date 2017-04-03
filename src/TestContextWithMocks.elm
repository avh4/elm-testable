module TestContextWithMocks
    exposing
        ( TestContext
        , MockTask
        , toTask
        , mockTask
        , start
        , model
        , update
        , expectMockTask
        , resolveMockTask
        , send
        , expectCmd
        , advanceTime
        , expectHttpRequest
        , resolveHttpRequest
        )

{-| This is a TestContext that allows mock Tasks.  You probably want to use
the `TestContext` module instead unless you are really sure of what you are doing.
-}

import Native.TestContext
import Dict exposing (Dict)
import Expect
import Http
import Json.Encode
import Mapper exposing (Mapper)
import PairingHeap exposing (PairingHeap)
import Testable.Task exposing (fromPlatformTask, Task(..))
import Time exposing (Time)


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


type MockTaskState msg
    = Pending (Mapper (Task msg msg))
    | Resolved String


isPending : MockTaskState msg -> Bool
isPending state =
    case state of
        Pending _ ->
            True

        _ ->
            False


type TestContext model msg
    = TestContext
        { program : TestableProgram model msg
        , model : model
        , pendingCmds : List (TestableCmd msg)
        , mockTasks : Dict String (MockTaskState msg)
        , pendingHttpRequests : Dict ( String, String ) (Http.Response String -> Task msg msg)
        , futureTasks : PairingHeap Time (Task msg msg)
        , now : Time
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


type MockTask x a
    = MockTask_ String


getId : MockTask x a -> String
getId (MockTask_ id) =
    id


toTask : MockTask x a -> Platform.Task x a
toTask (MockTask_ id) =
    Native.TestContext.mockTask id


mockTask : String -> MockTask x a
mockTask =
    MockTask_


start : Program flags model msg -> TestContext model msg
start getProgram =
    let
        program =
            getProgram
                |> extractProgram "<TestContext fake module>"
    in
        TestContext
            { program = program
            , model = Tuple.first program.init
            , pendingCmds = []
            , mockTasks = Dict.empty
            , pendingHttpRequests = Dict.empty
            , futureTasks = PairingHeap.empty
            , now = 0
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
            processTask (fromPlatformTask task) (TestContext context)


processTask : Task msg msg -> TestContext model msg -> TestContext model msg
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
                    | mockTasks =
                        context.mockTasks
                            |> Dict.insert label (Pending mapper)
                }

        SleepTask delay next ->
            TestContext
                { context
                    | futureTasks =
                        context.futureTasks
                            |> PairingHeap.insert (context.now + delay) next

                    -- TODO: make sure the offset is set based on the current now when the task is initiated, not when it is created
                }

        HttpTask options next ->
            TestContext
                { context
                    | pendingHttpRequests =
                        context.pendingHttpRequests
                            |> Dict.insert
                                ( options.method, options.url )
                                next
                }

        SpawnedTask task next ->
            (TestContext context)
                |> processTask
                    (task
                        |> Testable.Task.fromPlatformTask
                        |> Testable.Task.map never
                        |> Testable.Task.mapError never
                    )
                |> processTask next

        NeverTask ->
            (TestContext context)


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


getPendingTask : String -> MockTask x a -> TestContext model msg -> Result String (Mapper (Task msg msg))
getPendingTask fnName mock (TestContext context) =
    let
        label =
            mock |> getId
    in
        case Dict.get label context.mockTasks of
            Just (Pending mapper) ->
                Ok mapper

            Just (Resolved previousValue) ->
                listFailure
                    "pending mock tasks"
                    "none were initiated"
                    (context.mockTasks |> Dict.filter (\_ -> isPending) |> Dict.keys)
                    (toString >> (++) "mockTask ")
                    ("to include (TestContext." ++ fnName ++ ")")
                    label
                    [ "but mockTask "
                        ++ (toString label)
                        ++ " was previously resolved"
                        ++ " with value "
                        ++ previousValue
                    ]
                    |> Err

            Nothing ->
                listFailure
                    "pending mock tasks"
                    "none were initiated"
                    (context.mockTasks |> Dict.filter (\_ -> isPending) |> Dict.keys)
                    (toString >> (++) "mockTask ")
                    ("to include (TestContext." ++ fnName ++ ")")
                    label
                    []
                    |> Err


expectMockTask : MockTask x a -> TestContext model msg -> Expect.Expectation
expectMockTask whichMock context =
    case getPendingTask "expectMockTask" whichMock context of
        Ok _ ->
            Expect.pass

        Err message ->
            Expect.fail message


listFailure : String -> String -> List a -> (a -> String) -> String -> a -> List String -> String
listFailure collectionName emptyIndicator actuals view expectationName expected extraInfo =
    [ [ if List.isEmpty actuals then
            collectionName ++ " (" ++ emptyIndicator ++ ")"
        else
            actuals
                |> List.map (view >> (++) "    - ")
                |> String.join "\n"
                |> ((++) (collectionName ++ ":\n"))
      , "╷"
      , "│ " ++ expectationName
      , "╵"
      , view expected
      ]
    , if List.isEmpty extraInfo then
        []
      else
        [ "" ]
    , extraInfo
    ]
        |> List.concat
        |> String.join "\n"


resolveMockTask : MockTask x a -> Result x a -> TestContext model msg -> Result String (TestContext model msg)
resolveMockTask mock result (TestContext context) =
    let
        label =
            mock |> getId
    in
        case getPendingTask "resolveMockTask" mock (TestContext context) of
            Err message ->
                Err message

            Ok mapper ->
                Mapper.apply mapper result
                    |> Result.map
                        (\next ->
                            TestContext
                                { context
                                    | mockTasks =
                                        Dict.insert label (Resolved <| toString result) context.mockTasks
                                }
                                |> processTask next
                        )


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
                Mapper.apply mapper value
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


advanceTime : Time -> TestContext model msg -> TestContext model msg
advanceTime dt (TestContext context) =
    case PairingHeap.findMin context.futureTasks of
        Nothing ->
            TestContext { context | now = context.now + dt }

        Just ( time, next ) ->
            -- TODO: update now before running
            -- TODO: make sure now is set correctly from time, not from dt
            -- TODO: continue until all tasks are done
            -- TODO: make sure now is set based on dt at the very end
            if time <= context.now + dt then
                TestContext
                    { context
                        | futureTasks = PairingHeap.deleteMin context.futureTasks
                    }
                    |> processTask next
            else
                TestContext { context | now = context.now + dt }


expectHttpRequest : String -> String -> TestContext model msg -> Expect.Expectation
expectHttpRequest method url (TestContext context) =
    if Dict.member ( method, url ) context.pendingHttpRequests then
        Expect.pass
    else
        -- TODO: use listFailure
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


resolveHttpRequest : String -> String -> String -> TestContext model msg -> Result String (TestContext model msg)
resolveHttpRequest method url responseBody (TestContext context) =
    case Dict.get ( method, url ) context.pendingHttpRequests of
        Just next ->
            Ok <|
                processTask
                    (next <|
                        { url = "TODO: not implemented yet"
                        , status = { code = 200, message = "OK" }
                        , headers = Dict.empty -- TODO
                        , body = responseBody
                        }
                    )
                    (TestContext
                        { context
                            | pendingHttpRequests =
                                Dict.remove ( method, url )
                                    context.pendingHttpRequests
                        }
                    )

        Nothing ->
            Err ("No HTTP request was made matching: " ++ method ++ " " ++ url)
