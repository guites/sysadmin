#!/bin/bash

# Runs the process-feeds cli from the brcrawl/backend module

set -e # exit on error
set -u # error on undefined variables

LOGS_DIR="/data/process-feeds"
timestamp=$(date -u +'%Y%m%d%H%M%S')

docker exec brcrawl_app bash -c "uv run flask process-feeds > $LOGS_DIR/$timestamp.log"
