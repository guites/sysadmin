#!/bin/bash

# Find blogs from new pt posts in bearblog discover section

set -e # exit on error
set -u # error on undefined variables

docker exec brcrawl_app bash -c "cd scraper/ && USER_AGENT='brcrawl (+https://brcrawl.guilhermegarcia.dev)' uv run scrapy bearblog_discover -a latest=bearblog-urls.txt -O bearblog-rss.jsonlprocess-feeds 2>&1 | tee $LOGS_DIR/$timestamp.log"
