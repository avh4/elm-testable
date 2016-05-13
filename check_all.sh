#!/bin/bash

set -ex

elm-make --yes
./run-tests.sh

cd examples
elm-make Main.elm
open index.html
