module TestContextWithMocks
    exposing
        ( TestContext
        , MockTask
        , Token
        , toTask
        , mockTask
        , start
        , model
        , update
        , expectMockTask
        , resolveMockTask
        , send
        , expectCmd
        , expectHttpRequest
        )

{-| This is a TestContext that allows mock Tasks.  You probably want to use
the `TestContext` module instead unless you are really sure of what you are doing.
-}

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


type TestContext mocks model msg
    = TestContext
        { program : TestableProgram model msg
        , model : model
        , mocks : mocks
        , pendingCmds : List (TestableCmd msg)
        , mockTasks : Dict String (MockTaskState msg)
        , pendingHttpRequests : Dict ( String, String ) (Task msg msg)
        , errors : List String
        }


setError : String -> TestContext mocks model msg -> TestContext mocks model msg
setError message (TestContext context) =
    TestContext { context | errors = message :: context.errors }


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


type Token
    = Token_


mockTask : Token -> String -> MockTask x a
mockTask _ =
    MockTask_


start : (mocks -> Program flags model msg) -> (Token -> mocks) -> TestContext mocks model msg
start getProgram createMocks =
    let
        mocks =
            createMocks Token_

        program =
            getProgram mocks
                |> extractProgram "<TestContext fake module>"
    in
        TestContext
            { program = program
            , model = Tuple.first program.init
            , mocks = mocks
            , pendingCmds = []
            , mockTasks = Dict.empty
            , pendingHttpRequests = Dict.empty
            , errors = []
            }
            |> processCmds (Tuple.second program.init)


processCmds : Cmd msg -> TestContext mocks model msg -> TestContext mocks model msg
processCmds cmds context =
    List.foldl processCmd context (extractCmds <| cmds)


processCmd : TestableCmd msg -> TestContext mocks model msg -> TestContext mocks model msg
processCmd cmd (TestContext context) =
    case cmd of
        Port home value ->
            TestContext { context | pendingCmds = context.pendingCmds ++ [ cmd ] }

        Task task ->
            processTask (fromPlatformTask task) (TestContext context)


processTask : Task msg msg -> TestContext mocks model msg -> TestContext mocks model msg
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


model : TestContext mocks model msg -> model
model (TestContext context) =
    context.model


update : msg -> TestContext mocks model msg -> TestContext mocks model msg
update msg (TestContext context) =
    let
        ( newModel, newCmds ) =
            context.program.update msg context.model
    in
        TestContext { context | model = newModel }
            |> processCmds newCmds


expectMockTask : (mocks -> MockTask x a) -> TestContext mocks model msg -> Expect.Expectation
expectMockTask whichMock (TestContext context) =
    let
        label =
            context.mocks |> whichMock |> getId
    in
        case Dict.get label context.mockTasks of
            Just (Pending _) ->
                Expect.pass

            Just (Resolved previousValue) ->
                listFailure
                    "pending mock tasks"
                    "none were initiated"
                    (context.mockTasks |> Dict.filter (\_ -> isPending) |> Dict.keys)
                    (toString >> (++) "mockTask ")
                    "to include (TestContext.expectMockTask)"
                    label
                    [ "but mockTask "
                        ++ (toString label)
                        ++ " was previously resolved"
                        ++ " with value "
                        ++ previousValue
                    ]

            Nothing ->
                listFailure
                    "pending mock tasks"
                    "none were initiated"
                    (context.mockTasks |> Dict.filter (\_ -> isPending) |> Dict.keys)
                    (toString >> (++) "mockTask ")
                    "to include (TestContext.expectMockTask)"
                    label
                    []


listFailure : String -> String -> List a -> (a -> String) -> String -> a -> List String -> Expect.Expectation
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
        |> Expect.fail


resolveMockTask : (mocks -> MockTask x a) -> Result x a -> TestContext mocks model msg -> TestContext mocks model msg
resolveMockTask whichMock result (TestContext context) =
    let
        label =
            context.mocks |> whichMock |> getId
    in
        case Dict.get label context.mockTasks of
            Nothing ->
                (TestContext context)
                    |> setError ("No mockTask matches: " ++ toString label)

            Just (Resolved previousValue) ->
                (TestContext context)
                    |> setError ("mockTask " ++ toString label ++ " was previously resolved with value " ++ previousValue)

            Just (Pending mapper) ->
                case
                    Mapper.apply mapper result
                of
                    Ok next ->
                        TestContext
                            { context
                                | mockTasks =
                                    Dict.insert label (Resolved <| toString result) context.mockTasks
                            }
                            |> processTask next

                    Err message ->
                        (TestContext context)
                            |> setError message


send :
    ((value -> msg) -> Sub msg)
    -> value
    -> TestContext mocks model msg
    -> Result String (TestContext mocks model msg)
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


pendingCmds : TestContext mocks model msg -> List (TestableCmd msg)
pendingCmds (TestContext context) =
    context.pendingCmds


{-|
If `cmd` is a batch, then this will return True only if all Cmds in the batch
are pending.
-}
hasPendingCmd : Cmd msg -> TestContext mocks model msg -> Bool
hasPendingCmd cmd (TestContext context) =
    let
        testableCmd =
            extractCmds cmd
    in
        List.all (\c -> List.member c context.pendingCmds) testableCmd


expectCmd : Cmd msg -> TestContext mocks model msg -> Expect.Expectation
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


expectHttpRequest : String -> String -> TestContext mocks model msg -> Expect.Expectation
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
