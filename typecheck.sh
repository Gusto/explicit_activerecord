#!/bin/bash

set -e

bundle check || bundle install --retry 1
bundle exec srb tc
STATUS=$?

exit $STATUS
