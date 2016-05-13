#!/bin/bash

set -ex

elm-make --yes
./run-tests.sh

cd examples
./run-tests.sh
elm-make Main.elm
open index.html
