module Tests exposing (all)

import EffectManagerTests
import FlagsTests
import HttpTests
import MockTaskTests
import ModelTests
import NavigationTests
import PortCmdTests
import PortSubTests
import TaskTests
import Test exposing (..)
import Testable.NavigationTests
import Testable.TaskTests
import TimeTests
import ViewTests


all : Test
all =
    describe "Testable"
        [ Testable.TaskTests.all

        -- Core Elm support
        , ModelTests.all
        , ViewTests.all
        , FlagsTests.all
        , PortCmdTests.all
        , PortSubTests.all
        , TaskTests.all
        , EffectManagerTests.all

        -- Low-level APIs
        , MockTaskTests.all

        -- Domain-specific APIs
        , HttpTests.all
        , TimeTests.all
        , NavigationTests.all
        , Testable.NavigationTests.all

        -- TODO: Random
        -- TODO: Add Websocket tests (see examples/tests/WebsocketChatTests)
        -- TODO: Window
        -- TODO: RAF
        ]
