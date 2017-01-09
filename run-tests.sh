#!/bin/bash

set -ex

cd tests
elm-package install --yes
cd -

elm-test
