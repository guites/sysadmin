#!/bin/bash

# Runs the refresh-latest-posts cli from the brcrawl/backend module

set -e # exit on error
set -u # error on undefined variables

docker exec brcrawl_app bash -c "uv run flask refresh-latest-posts"
