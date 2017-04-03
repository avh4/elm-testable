module Tests exposing (all)

import Test exposing (..)
import CmdTests
import HttpTests
import MockTaskTests
import ModelTests
import SubTests
import TaskTests
import Testable.TaskTests
import TimeTests


all : Test
all =
    describe "Testable"
        [ Testable.TaskTests.all
        , ModelTests.all
        , CmdTests.all
        , TaskTests.all

        -- TODO , describe "Process.sleep" []
        , MockTaskTests.all
        , HttpTests.all
        , SubTests.all
        , TimeTests.all

        -- TODO , describe "Flags" []
        ]
