module TestContextWithMocks
    exposing
        ( TestContext
        , MockTask
        , toTask
        , mockTask
        , start
        , startWithFlags
        , model
        , update
        , expectMockTask
        , resolveMockTask
        , send
        , expectCmd
        , advanceTime
        , expectHttpRequest
        , resolveHttpRequest
        , expect
        )

{-| This is a TestContext that allows mock Tasks. You probably want to use
the `TestContext` module instead unless you are really sure of what you are doing.
-}

import Native.TestContext
import DefaultDict exposing (DefaultDict)
import Dict exposing (Dict)
import Expect exposing (Expectation)
import Fifo exposing (Fifo)
import Http
import Json.Encode
import Mapper exposing (Mapper)
import PairingHeap exposing (PairingHeap)
import Set exposing (Set)
import Testable.EffectManager as EffectManager exposing (EffectManager)
import Testable.Task exposing (fromPlatformTask, Task(..), ProcessId(..))
import Time exposing (Time)


debug : String -> a -> a
debug label =
    ( identity, Debug.log label )
        -- Change to Tuple.second to enable debug output
        |> Tuple.first


type alias TestableProgram model msg =
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    }


type TestableCmd msg
    = Task (Platform.Task Never msg)
    | PortCmd String Json.Encode.Value
    | EffectManagerCmd String EffectManager.MyCmd


type TestableSub msg
    = PortSub String (Mapper msg)
    | EffectManagerSub String EffectManager.MySub


type MockTaskState msg
    = Pending (Mapper (Task Never msg))
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
        , outgoingPortValues : Dict String (List Json.Encode.Value)
        , mockTasks : Dict String (MockTaskState msg)
        , pendingHttpRequests : Dict ( String, String ) (Http.Response String -> Task Never msg)
        , futureTasks : PairingHeap Time ( ProcessId, Task Never msg )
        , now : Time
        , sequence : Int
        , nextProcessId : Int
        , killedProcesses : Set Int
        , processMailboxes : DefaultDict String (Fifo ( Int, EffectManager.Message ))
        , workQueue : Fifo String
        , effectManagerStates : Dict String EffectManager.State
        , transcript : List ( Int, Task Never msg )
        }


extractProgram : String -> Maybe flags -> Program flags model msg -> TestableProgram model msg
extractProgram moduleName flags =
    Native.TestContext.extractProgram moduleName flags


extractBag : (tagger -> leaf -> x) -> (x -> a -> a) -> a -> bag -> a
extractBag =
    Native.TestContext.extractBag


extractCmds :
    Cmd msg
    ->
        { ports : Dict String (List Json.Encode.Value)
        , effectManagers : Dict String (List EffectManager.MyCmd)
        , tasks : List (Task Never msg)
        }
extractCmds =
    let
        init =
            { ports = Dict.empty
            , effectManagers = Dict.empty
            , tasks = []
            }

        reduce cmd acc =
            case cmd of
                PortCmd home value ->
                    { acc
                        | ports =
                            Dict.update home
                                (Maybe.withDefault [] >> (::) value >> Just)
                                acc.ports
                    }

                EffectManagerCmd home value ->
                    { acc
                        | effectManagers =
                            Dict.update home
                                (Maybe.withDefault [] >> (::) value >> Just)
                                acc.effectManagers
                    }

                Task t ->
                    { acc
                        | tasks = (fromPlatformTask t) :: acc.tasks
                    }

        done { ports, effectManagers, tasks } =
            { ports = Dict.map (\_ -> List.reverse) ports
            , effectManagers = Dict.map (\_ -> List.reverse) effectManagers
            , tasks = List.reverse tasks
            }
    in
        extractBag Native.TestContext.extractCmd reduce init
            >> done


extractSubs :
    Sub msg
    ->
        { ports : Dict String (List (Mapper msg))
        , effectManagers : Dict String (List EffectManager.MySub)
        }
extractSubs =
    let
        init =
            { ports = Dict.empty
            , effectManagers = Dict.empty
            }

        reduce sub acc =
            case sub of
                PortSub home mapper ->
                    { acc
                        | ports =
                            Dict.update home
                                (Maybe.withDefault [] >> (::) mapper >> Just)
                                acc.ports
                    }

                EffectManagerSub home value ->
                    { acc
                        | effectManagers =
                            Dict.update home
                                (Maybe.withDefault [] >> (::) value >> Just)
                                acc.effectManagers
                    }

        done { ports, effectManagers } =
            { ports = Dict.map (\_ -> List.reverse) ports
            , effectManagers = Dict.map (\_ -> List.reverse) effectManagers
            }
    in
        extractBag Native.TestContext.extractSub reduce init
            >> done


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


orCrash : String -> Maybe a -> a
orCrash message maybe =
    case maybe of
        Just x ->
            x

        Nothing ->
            Debug.crash message


startWithFlags : flags -> Program flags model msg -> TestContext model msg
startWithFlags flags realProgram =
    start_ (Just flags) realProgram


start : Program Never model msg -> TestContext model msg
start realProgram =
    start_ Nothing realProgram


start_ : Maybe flags -> Program flags model msg -> TestContext model msg
start_ flags realProgram =
    let
        _ =
            debug "start" flags

        program =
            realProgram
                |> extractProgram "<TestContext fake module>" flags

        model =
            Tuple.first program.init

        initEffectManager home em =
            em.init
                |> fromPlatformTask
                |> Testable.Task.mapError never
                |> Testable.Task.andThen (NewEffectManagerState "start" home)

        initEffectManagers context =
            Dict.foldl
                (\home em -> processTask (ProcessId -1) (initEffectManager home em))
                context
                (EffectManager.extractEffectManagers ())
    in
        TestContext
            { program = program
            , model = model
            , outgoingPortValues = Dict.empty
            , mockTasks = Dict.empty
            , pendingHttpRequests = Dict.empty
            , futureTasks = PairingHeap.empty
            , now = 0
            , sequence = 0
            , nextProcessId = 1
            , killedProcesses = Set.empty
            , processMailboxes = DefaultDict.empty Fifo.empty
            , workQueue = Fifo.empty
            , effectManagerStates = Dict.empty
            , transcript = []
            }
            |> initEffectManagers
            |> dispatchEffects
                (Tuple.second program.init)
                (program.subscriptions model)
            |> drainWorkQueue


drainWorkQueue : TestContext model msg -> TestContext model msg
drainWorkQueue (TestContext context) =
    case Fifo.remove (debug "drainWorkQueue" <| context.workQueue) of
        ( Nothing, _ ) ->
            TestContext context

        ( Just home, rest ) ->
            case Fifo.remove (DefaultDict.get home context.processMailboxes) of
                ( Nothing, _ ) ->
                    TestContext { context | workQueue = rest }
                        |> drainWorkQueue

                ( Just ( _, message ), remaining ) ->
                    TestContext
                        { context
                            | workQueue = rest
                            , processMailboxes = DefaultDict.insert home remaining context.processMailboxes
                        }
                        |> processMessage home message
                        |> drainWorkQueue


processMessage : String -> EffectManager.Message -> TestContext model msg -> TestContext model msg
processMessage home message (TestContext context) =
    let
        effectManager =
            EffectManager.extractEffectManager home
                |> orCrash ("Could not extract effect manager: " ++ home)

        currentState =
            Dict.get home context.effectManagerStates
                |> orCrash ("There's no recorded state for effect manager: " ++ home)

        newStateTask =
            (case message of
                EffectManager.Self selfMsg ->
                    effectManager.onSelfMsg selfMsg currentState

                EffectManager.Fx cmds subs ->
                    effectManager.onEffects cmds subs currentState
            )
                |> fromPlatformTask
                |> Testable.Task.mapError never
                |> Testable.Task.andThen (NewEffectManagerState "onSelfMsg" home)
    in
        TestContext context
            |> processTask (ProcessId 0) newStateTask


enqueueMessage : String -> EffectManager.Message -> TestContext model msg -> TestContext model msg
enqueueMessage home message (TestContext context) =
    let
        _ =
            debug "enqueueMessage" ( home, message )
    in
        TestContext
            { context
                | processMailboxes =
                    context.processMailboxes
                        |> DefaultDict.update home (Fifo.insert ( context.sequence, message ))
                , workQueue =
                    Fifo.insert home context.workQueue
            }


dispatchEffects : Cmd msg -> Sub msg -> TestContext model msg -> TestContext model msg
dispatchEffects cmd sub (TestContext context) =
    let
        cmds =
            extractCmds cmd

        subs =
            extractSubs sub

        fxs =
            Dict.merge
                (\home c -> Dict.insert home <| EffectManager.Fx c [])
                (\home c s -> Dict.insert home <| EffectManager.Fx c s)
                (\home s -> Dict.insert home <| EffectManager.Fx [] s)
                cmds.effectManagers
                subs.effectManagers
                Dict.empty

        -- We iterate all effect managers (not just the ones we have fx for)
        -- because there might be some that are no longer subscribed to that
        -- were previously subscribed to.
        applyEffects =
            Dict.merge
                (\home em -> enqueueMessage home <| EffectManager.Fx [] [])
                (\home em fx -> enqueueMessage home fx)
                (\home fx -> Debug.crash <| "Missing effect manager: " ++ home)
                (EffectManager.extractEffectManagers ())
                fxs
    in
        TestContext
            { context
                | outgoingPortValues =
                    Dict.merge
                        (\home old d -> d)
                        (\home old new d -> Dict.insert home (old ++ new) d)
                        (\home new d -> Dict.insert home new d)
                        context.outgoingPortValues
                        cmds.ports
                        context.outgoingPortValues
            }
            |> applyEffects
            |> flip (List.foldl (processTask (ProcessId -2))) cmds.tasks


{-| This is a workaround for <https://github.com/elm-lang/elm-compiler/issues/1287>

If processTask gets tail call optimization applied, then due to elm-compiler#1287,
when resolving tasks that are produced by the callback of another task, the variables
in the call stack can get mutated and refer to the wrong objects.

To avoid this, processTask should call processTask_preventTailCallOptimization
instead of calling itself, which will prevent the tail call optimization, and
prevent the bug from being triggered.

-}
processTask_preventTailCallOptimization : ProcessId -> Task Never msg -> TestContext model msg -> TestContext model msg
processTask_preventTailCallOptimization =
    processTask


processTask : ProcessId -> Task Never msg -> TestContext model msg -> TestContext model msg
processTask pid task (TestContext context_) =
    let
        _ =
            debug ("processTask:" ++ toString pid) task

        context =
            { context_
                | sequence = context_.sequence + 1
                , transcript = ( context_.sequence + 1, task ) :: context_.transcript
            }
    in
        case task of
            Success msg ->
                TestContext context
                    |> update msg

            Failure x ->
                never x

            IgnoredTask ->
                TestContext context

            MockTask label mapper ->
                TestContext
                    { context
                        | mockTasks =
                            context.mockTasks
                                |> Dict.insert label (Pending mapper)
                    }

            ToApp msg next ->
                TestContext context
                    |> update (EffectManager.unwrapAppMsg msg)
                    |> processTask_preventTailCallOptimization pid next

            ToEffectManager home selfMsg next ->
                TestContext context
                    |> enqueueMessage home (EffectManager.Self selfMsg)
                    |> processTask_preventTailCallOptimization pid next

            NewEffectManagerState junk home newState ->
                TestContext
                    { context
                        | effectManagerStates = Dict.insert home newState context.effectManagerStates
                    }

            Core_NativeScheduler_sleep delay next ->
                TestContext
                    { context
                        | futureTasks =
                            context.futureTasks
                                |> PairingHeap.insert (context.now + delay) ( pid, next () )
                    }

            Core_NativeScheduler_spawn task next ->
                let
                    spawnedProcessId =
                        ProcessId context.nextProcessId
                in
                    TestContext { context | nextProcessId = context.nextProcessId + 1 }
                        -- ??? which order should these be processed in?
                        -- ??? ideally nothing should depened on the order, but maybe we should
                        -- ??? simulate the same order that the Elm runtime would result in?
                        |> processTask spawnedProcessId (task |> Testable.Task.map never)
                        |> processTask_preventTailCallOptimization pid (next spawnedProcessId)

            Core_NativeScheduler_kill (ProcessId processId) next ->
                TestContext { context | killedProcesses = Set.insert processId context.killedProcesses }
                    |> processTask_preventTailCallOptimization pid next

            Core_Time_now next ->
                TestContext context
                    |> processTask_preventTailCallOptimization pid (next context.now)

            Core_Time_setInterval delay recurringTask ->
                let
                    step () =
                        Core_NativeScheduler_sleep delay (\() -> recurringTask)
                            |> Testable.Task.andThen step
                            |> Testable.Task.mapError never
                in
                    TestContext context
                        |> processTask_preventTailCallOptimization pid (step ())

            Http_NativeHttp_toTask options next ->
                TestContext
                    { context
                        | pendingHttpRequests =
                            context.pendingHttpRequests
                                |> Dict.insert
                                    ( options.method, options.url )
                                    next
                    }


model : TestContext model msg -> model
model (TestContext context) =
    context.model


update : msg -> TestContext model msg -> TestContext model msg
update msg (TestContext context) =
    let
        _ =
            debug "update" msg

        ( newModel, newCmds ) =
            context.program.update msg context.model

        newSubs =
            context.program.subscriptions newModel
    in
        TestContext { context | model = newModel }
            |> dispatchEffects newCmds newSubs
            |> drainWorkQueue


getPendingTask : String -> MockTask x a -> TestContext model msg -> Result String (Mapper (Task Never msg))
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


expectMockTask : MockTask x a -> TestContext model msg -> Expectation
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
                                |> processTask (ProcessId -3) next
                         -- TODO: drain work queue
                        )


isPortSub : TestableSub msg -> Maybe ( String, Mapper msg )
isPortSub sub =
    case sub of
        PortSub name mapper ->
            Just ( name, mapper )

        _ ->
            Nothing


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
                |> .ports

        portName =
            extractSubPortName subPort
    in
        case Dict.get portName subs |> Maybe.withDefault [] of
            [] ->
                Err ("Not subscribed to port: " ++ portName)

            mappers ->
                List.foldl
                    (\mapper c -> Mapper.apply mapper value |> Result.map2 (flip update) c)
                    (Ok <| TestContext context)
                    mappers


{-| If `cmd` is a batch, then this will return True only if all Cmds in the batch
are pending.
-}
hasPendingCmd : Cmd msg -> TestContext model msg -> Bool
hasPendingCmd cmd (TestContext context) =
    let
        expected =
            extractCmds cmd
                |> .ports

        actual =
            context.outgoingPortValues
    in
        Dict.merge
            (\_ exp b -> b && exp == [])
            (\_ exp act b -> b && List.all (flip List.member act) exp)
            (\_ act b -> b)
            expected
            actual
            True


expectCmd : Cmd msg -> TestContext model msg -> Expectation
expectCmd expected (TestContext context) =
    if hasPendingCmd expected (TestContext context) then
        Expect.pass
    else
        -- TODO: nicer failure messages like expectHttpRequest
        [ toString <| context.outgoingPortValues
        , "╷"
        , "│ TestContext.expectCmd"
        , "╵"
        , toString <| .ports <| extractCmds expected
        ]
            |> String.join "\n"
            |> Expect.fail


advanceTime : Time -> TestContext model msg -> TestContext model msg
advanceTime dt (TestContext context) =
    advanceTimeUntil (context.now + dt) (TestContext context)


advanceTimeUntil : Time -> TestContext model msg -> TestContext model msg
advanceTimeUntil targetTime (TestContext context) =
    case PairingHeap.findMin (debug ("advanceTimeUntil:" ++ toString targetTime) context.futureTasks) of
        Nothing ->
            TestContext { context | now = targetTime }

        Just ( time, ( ProcessId processId, next ) ) ->
            if Set.member processId (debug "killedProcesses" context.killedProcesses) then
                TestContext { context | futureTasks = PairingHeap.deleteMin context.futureTasks }
                    |> advanceTimeUntil targetTime
            else if time <= targetTime then
                TestContext
                    { context
                        | futureTasks = PairingHeap.deleteMin context.futureTasks
                        , now = time
                    }
                    |> processTask (ProcessId processId) next
                    |> drainWorkQueue
                    |> advanceTimeUntil targetTime
            else
                TestContext { context | now = targetTime }


expectHttpRequest : String -> String -> TestContext model msg -> Expectation
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
                -- TODO: need to drain the work queue
                processTask (ProcessId -4)
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


expect : (TestContext model msg -> a) -> (a -> Expectation) -> TestContext model msg -> Expectation
expect get check (TestContext context) =
    case Expect.getFailure (get (TestContext context) |> check) of
        Nothing ->
            Expect.pass

        Just { given, message } ->
            Expect.fail <|
                message
                    ++ "\n\n\nThe following tasks we processed during the test:\n"
                    ++ show "  - "
                        (\( i, t ) -> toString i ++ ": " ++ toString t)
                        (List.reverse context.transcript)
                    ++ "\nThe following messages were unprocessed:\n"
                    ++ show "  - "
                        (\( home, msgs ) -> home ++ "\n" ++ show "      - " toString (Fifo.toList msgs))
                        (DefaultDict.toList context.processMailboxes)


show : String -> (a -> String) -> List a -> String
show pre f list =
    String.concat (list |> List.map (f >> (++) pre >> flip (++) "\n"))
