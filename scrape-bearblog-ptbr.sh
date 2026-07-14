#!/bin/bash

# Find blogs from new pt posts in bearblog discover section

set -e # exit on error
set -u # error on undefined variables

USER_AGENT="brcrawl (+https://brcrawl.guilhermegarcia.dev)"
UV="/home/ubuntu/.local/bin/uv"
SCRAPER_DIR="/home/ubuntu/brcrawl/scraper"
LOCAL_DIR="/home/ubuntu/data/brcrawl/scrape-bearblog-ptbr"

LATEST_FILE="$LOCAL_DIR/latest.txt"
SCRAPE_OUTPUT="$LOCAL_DIR/rss.jsonl"
URLS_FILE="$LOCAL_DIR/urls.txt"
RSS_FILE="$LOCAL_DIR/rss.jsonl"

SCRAPE_CMD="$UV run scrapy crawl bearblog_discover -O $SCRAPE_OUTPUT"

LATEST=$(cat "$LATEST_FILE")
if [ ! -z "$LATEST" ]; then
    SCRAPE_CMD="$SCRAPE_CMD -a latest=$LATEST"
fi

cd "$SCRAPER_DIR"
USER_AGENT="$USER_AGENT" $SCRAPE_CMD

HAS_OUTPUT=$(head -n1 "$SCRAPE_OUTPUT")
if [ -z "$HAS_OUTPUT" ]; then
    echo "No new posts since last run. Exiting." && exit 0;
fi
echo "Updating latest scrapped post"
echo "$HAS_OUTPUT" | jq -r .post_url > "$LATEST_FILE"

echo "Generating list of scrapped blogs"
cat "$SCRAPE_OUTPUT" | jq -r .blog_url | sort -u > "$URLS_FILE"

echo "Getting the rss feed of each blog"
USER_AGENT="$USER_AGENT" "$UV" run scrapy crawl rss -a urls_file="$URLS_FILE" -o "$RSS_FILE"

echo "Importing rss feeds"
docker exec -i brcrawl_app bash -c "uv run flask import-feeds /data/scrape-bearblog-ptbr/rss.jsonl --feed-status verified"

echo "Removing artifacts"
rm "$URLS_FILE"
rm "$RSS_FILE"

echo "Done! Exiting."
