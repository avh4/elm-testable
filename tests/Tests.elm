module Tests exposing (all)

import Test exposing (..)
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
        , ModelTests.all
        , TaskTests.all

        -- TODO , describe "Process.sleep" []
        , MockTaskTests.all
        , HttpTests.all
        , PortCmdTests.all
        , PortSubTests.all
        , TimeTests.all

        -- TODO , describe "Flags" []
        ]
