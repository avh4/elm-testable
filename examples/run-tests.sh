#!/bin/bash

set -ex

cd tests
elm-make TestRunner.elm --output tests.js
node tests.js
