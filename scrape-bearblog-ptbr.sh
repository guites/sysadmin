#!/bin/bash

# Find blogs from new pt posts in bearblog discover section

set -e # exit on error
set -u # error on undefined variables

USER_AGENT="brcrawl (+https://brcrawl.guilhermegarcia.dev)"
BASE_DIR="/data/scrape-bearblog-ptbr"
SCRAPE_OUTPUT="$BASE_DIR/rss.jsonl"
SCRAPE_CMD="uv run scrapy bearblog_discover -O $SCRAPE_OUTPUT"

LATEST_FILE="$BASE_DIR/latest.txt"
LATEST=$(cat "$LATEST_FILE")

URLS_FILE="$BASE_DIR/urls.txt"
RSS_FILE="$BASE_DIR/rss.jsonl"

if [ ! -z "$LATEST" ]; then
    SCRAPE_CMD="$SCRAPE_CMD -a latest='$LATEST'"
fi

docker exec brcrawl_app bash <<EOF
cd scraper/
USER_AGENT="$USER_AGENT" "$SCRAPE_CMD"
HAS_OUTPUT=$(head -n1 "$SCRAPE_OUTPUT")
if [ -z "$HAS_OUTPUT" ]; then
    echo "No new posts since last run. Exiting." && exit 0;
fi
echo "Updating latest scrapped post"
echo "$HAS_OUTPUT" | jq -r .post_url > "$LATEST_FILE"

echo "Generating list of scrapped blogs"
cat "$SCRAPE_OUTPUT" | jq -r .blog_url | sort -u > "$URLS_FILE"

echo "Getting the rss feed of each blog"
USER_AGENT="$USER_AGENT" uv run scrapy crawl rss -a urls_file="$URLS_FILE" -o "$RSS_FILE"

echo "Importing rss feeds"
uv run flask import-feeds "$RSS_FILE"

echo "Done! Exiting."
EOF
