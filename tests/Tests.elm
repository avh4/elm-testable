module Tests exposing (all)

import Test exposing (..)
import EffectManagerTests
import HttpTests
import MockTaskTests
import ModelTests
import PortCmdTests
import PortSubTests
import TaskTests
import Testable.TaskTests
import TimeTests


all : Test
all =
    describe "Testable"
        [ Testable.TaskTests.all

        -- Core Elm support
        , ModelTests.all
        , TaskTests.all
        , PortCmdTests.all
        , PortSubTests.all
        , EffectManagerTests.all

        -- Low-level APIs
        , MockTaskTests.all

        -- Domain-specific APIs
        , HttpTests.all
        , TimeTests.all

        -- TODO , describe "Flags" []
        ]
