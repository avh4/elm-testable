module TestContextInternal
    exposing
        ( MockTask
        , TestContext(..)
        , advanceTime
        , done
          -- private to elm-testable
        , drainWorkQueue
        , error
        , expect
        , expectCmd
        , expectMockTask
        , expectModel
        , expectView
        , mockTask
        , processTask
        , resolveMockTask
        , send
        , simulate
        , start
        , startWithFlags
        , toTask
        , update
        , withContext
        )

import DefaultDict exposing (DefaultDict)
import Dict exposing (Dict)
import Expect exposing (Expectation)
import Fifo exposing (Fifo)
import Html exposing (Html)
import Http
import Json.Encode
import Mapper exposing (Mapper)
import Native.TestContext
import PairingHeap exposing (PairingHeap)
import Set exposing (Set)
import Test.Html.Events as Events exposing (Event)
import Test.Html.Query
import Test.Runner
import Testable.EffectManager as EffectManager exposing (EffectManager)
import Testable.Task exposing (ProcessId(..), Task(..), fromPlatformTask)
import Time exposing (Time)
import WebSocket.LowLevel


debug : String -> a -> a
debug label =
    ( identity, Debug.log label )
        -- Change to Tuple.second to enable debug output
        |> Tuple.first


type alias TestableProgram model msg =
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Html msg
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


type alias ActiveContext model msg =
    { program : TestableProgram model msg
    , model : model
    , outgoingPortValues : Dict String (List Json.Encode.Value)
    , mockTasks : Dict String (MockTaskState msg)
    , pendingHttpRequests : Dict ( String, String ) (Result Http.Error String -> Task Never msg)
    , futureTasks : PairingHeap Time ( ProcessId, Task Never msg )
    , now : Time
    , sequence : Int
    , nextProcessId : Int
    , killedProcesses : Set Int
    , processMailboxes : DefaultDict String (Fifo ( Int, EffectManager.Message ))
    , workQueue : Fifo String
    , effectManagerStates : Dict String EffectManager.State

    -- websockets
    , pendingWebSocketConnections : Dict String (Result WebSocket.LowLevel.BadOpen () -> Task Never msg)
    , pendingWebSocketMessages : DefaultDict String (Fifo String)

    -- reporting info
    , taskTranscript : List ( Int, Task Never msg )
    , msgTranscript : List ( Int, msg )
    }


type TestContext model msg
    = TestContext (ActiveContext model msg)
    | TestError
        { error : String
        , model : model
        , processMailboxes : Dict String (List ( Int, EffectManager.Message ))
        , taskTranscript : List ( Int, Task Never msg )
        , msgTranscript : List ( Int, msg )
        }


withContext : (ActiveContext model msg -> TestContext model msg) -> TestContext model msg -> TestContext model msg
withContext f context =
    case context of
        TestContext c ->
            f c

        TestError _ ->
            -- TODO: track the steps that didn't run
            context


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
                        | tasks = fromPlatformTask t :: acc.tasks
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

        -- websockets
        , pendingWebSocketConnections = Dict.empty
        , pendingWebSocketMessages = DefaultDict.empty Fifo.empty

        -- reporting
        , taskTranscript = []
        , msgTranscript = []
        }
        |> initEffectManagers
        |> dispatchEffects
            (Tuple.second program.init)
            (program.subscriptions model)
        |> drainWorkQueue


drainWorkQueue : TestContext model msg -> TestContext model msg
drainWorkQueue =
    withContext <|
        \context ->
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
processMessage home message =
    withContext <|
        \context ->
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
enqueueMessage home message =
    withContext <|
        \context ->
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
dispatchEffects cmd sub =
    withContext <|
        \context ->
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
processTask pid task =
    withContext <|
        \context_ ->
            let
                _ =
                    debug ("processTask:" ++ toString pid) task

                context =
                    { context_
                        | sequence = context_.sequence + 1
                        , taskTranscript = ( context_.sequence + 1, task ) :: context_.taskTranscript
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

                Http_NativeHttp_toTask request ->
                    TestContext
                        { context
                            | pendingHttpRequests =
                                context.pendingHttpRequests
                                    |> Dict.insert
                                        ( request.method, request.url )
                                        request.callback
                        }

                WebSocket_NativeWebSocket_open url settings next ->
                    TestContext
                        { context
                            | pendingWebSocketConnections =
                                context.pendingWebSocketConnections
                                    |> Dict.insert url next
                        }

                WebSocket_NativeWebSocket_send url string next ->
                    -- TODO: verify that the connection is open
                    TestContext
                        { context
                            | pendingWebSocketMessages =
                                context.pendingWebSocketMessages
                                    |> DefaultDict.update url (Fifo.insert string)
                        }
                        |> processTask_preventTailCallOptimization pid (next Nothing)


update : msg -> TestContext model msg -> TestContext model msg
update msg =
    withContext <|
        \context ->
            let
                _ =
                    debug "update" msg

                ( newModel, newCmds ) =
                    context.program.update msg context.model

                newSubs =
                    context.program.subscriptions newModel
            in
            TestContext
                { context
                    | model = newModel
                    , msgTranscript = ( context.sequence, msg ) :: context.msgTranscript
                }
                |> dispatchEffects newCmds newSubs
                |> drainWorkQueue


getPendingTask : String -> MockTask x a -> ActiveContext model msg -> Result String (Mapper (Task Never msg))
getPendingTask fnName mock context =
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
                    ++ toString label
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
expectMockTask whichMock =
    expect "TestContext.expectMockTask"
        (getPendingTask "expectMockTask" whichMock)
        (\result ->
            case result of
                Ok _ ->
                    Expect.pass

                Err message ->
                    Expect.fail message
        )


listFailure : String -> String -> List a -> (a -> String) -> String -> a -> List String -> String
listFailure collectionName emptyIndicator actuals view expectationName expected extraInfo =
    [ [ if List.isEmpty actuals then
            collectionName ++ " (" ++ emptyIndicator ++ ")"
        else
            actuals
                |> List.map (view >> (++) "    - ")
                |> String.join "\n"
                |> (++) (collectionName ++ ":\n")
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


resolveMockTask : MockTask x a -> Result x a -> TestContext model msg -> TestContext model msg
resolveMockTask mock result =
    withContext <|
        \context ->
            let
                label =
                    mock |> getId
            in
            case getPendingTask "resolveMockTask" mock context of
                Err message ->
                    error context message

                Ok mapper ->
                    Mapper.apply mapper result
                        |> (\next ->
                                TestContext
                                    { context
                                        | mockTasks =
                                            Dict.insert label (Resolved <| toString result) context.mockTasks
                                    }
                                    |> processTask (ProcessId -3) next
                                    -- TODO: drain work queue
                                    |> identity
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
    -> TestContext model msg
send subPort value =
    withContext <|
        \context ->
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
                    error context ("Not subscribed to port: " ++ portName)

                mappers ->
                    List.foldl
                        (\mapper c -> Mapper.apply mapper value |> flip update c)
                        (TestContext context)
                        mappers


{-| If `cmd` is a batch, then this will return True only if all Cmds in the batch
are pending.
-}
hasPendingCmd : Cmd msg -> ActiveContext model msg -> Result String Bool
hasPendingCmd cmd context =
    let
        expected =
            extractCmds cmd
                |> .ports

        actual =
            context.outgoingPortValues
    in
    if Dict.isEmpty expected then
        Err ("The given Cmd " ++ toString cmd ++ " is not supported by expectCmd.\n(Only Cmd ports defined in port modules are supported.)")
    else
        Dict.merge
            (\_ exp b -> b && exp == [])
            (\_ exp act b -> b && List.all (flip List.member act) exp)
            (\_ act b -> b)
            expected
            actual
            True
            |> Ok


expectCmd : Cmd msg -> TestContext model msg -> Expectation
expectCmd expected =
    expect "TestContext.expectCmd"
        identity
        (\context ->
            case hasPendingCmd expected context of
                Err message ->
                    Expect.fail message

                Ok True ->
                    Expect.pass

                Ok False ->
                    -- TODO: nicer failure messages like expectHttpRequest
                    [ toString <| context.outgoingPortValues
                    , "╷"
                    , "│ TestContext.expectCmd"
                    , "╵"
                    , toString <| .ports <| extractCmds expected
                    ]
                        |> String.join "\n"
                        |> Expect.fail
        )


advanceTime : Time -> TestContext model msg -> TestContext model msg
advanceTime dt context =
    flip withContext context <|
        \c ->
            advanceTimeUntil (c.now + dt) context


advanceTimeUntil : Time -> TestContext model msg -> TestContext model msg
advanceTimeUntil targetTime =
    withContext <|
        \context ->
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


error : ActiveContext model msg -> String -> TestContext model msg
error context error =
    TestError
        { error = error
        , model = context.model
        , processMailboxes =
            context.processMailboxes
                |> DefaultDict.toDict
                |> Dict.map (\_ -> Fifo.toList)
        , taskTranscript = context.taskTranscript
        , msgTranscript = context.msgTranscript
        }


expect : String -> (ActiveContext model msg -> a) -> (a -> Expectation) -> TestContext model msg -> Expectation
expect entryName get check context_ =
    case context_ of
        TestContext context ->
            case Test.Runner.getFailure (get context |> check) of
                Nothing ->
                    Expect.pass

                Just { given, message } ->
                    Expect.fail <|
                        report entryName <|
                            error context message

        TestError details ->
            Expect.fail <| report entryName context_


report : String -> TestContext model msg -> String
report entryName context =
    case context of
        TestContext _ ->
            "No error"

        TestError details ->
            "▼ "
                ++ entryName
                ++ "\n\n"
                ++ "The following tasks were processed during the test:\n"
                ++ show "  "
                    (\( i, t ) -> toString i ++ ". " ++ toString t)
                    (List.reverse details.taskTranscript)
                ++ "\nThe following messages were unprocessed:\n"
                ++ show "  - "
                    (\( home, msgs ) -> home ++ "\n" ++ show "      - " toString msgs)
                    (Dict.toList <| Dict.filter (\_ list -> list /= []) details.processMailboxes)
                ++ "\nThe following msgs were processed during the test:\n"
                ++ show "  - "
                    (\( i, t ) -> toString i ++ ": " ++ toString t)
                    (List.reverse details.msgTranscript)
                ++ "\nThe final state of the model:\n    "
                ++ toString details.model
                ++ "\n\n\n"
                ++ details.error


show : String -> (a -> String) -> List a -> String
show pre f list =
    String.concat (list |> List.map (f >> (++) pre >> flip (++) "\n"))


expectModel : (model -> Expectation) -> TestContext model msg -> Expectation
expectModel check context =
    expect "TestContext.expectModel" .model check context


expectView : TestContext model msg -> Test.Html.Query.Single msg
expectView context =
    case context of
        TestContext c ->
            c.program.view c.model |> Test.Html.Query.fromHtml

        TestError details ->
            -- TODO: ideally there would be a way we could create a Query.Single
            -- that is already in an error state with our custom message
            Html.text (report "expectView" context) |> Test.Html.Query.fromHtml


simulate : (Test.Html.Query.Single msg -> Test.Html.Query.Single msg) -> Event -> TestContext model msg -> TestContext model msg
simulate eventTrigger event context =
    let
        eventResult =
            eventTrigger (expectView context)
                |> Events.simulate event
                |> Events.eventResult
    in
    case eventResult of
        Ok msg ->
            update msg context

        Err err ->
            withContext (flip error err) context


done : TestContext model msg -> Expectation
done =
    expect "TestContext.done" (always ()) (always Expect.pass)
