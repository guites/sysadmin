#!/bin/bash
set -e # exit on error
set -u # error on undefined variables

HUGO="/home/ubuntu/.local/bin/hugo"

SCRIPT_DIR=/home/ubuntu/scripts
DB_DIR=/home/ubuntu/data/brcrawl
WEBSITE_DIR=/home/ubuntu/guilhermegarcia.dev
BRCRAWL_DIR=/home/ubuntu/brcrawl/website

FEEDS_TXT_FILE="$SCRIPT_DIR/feeds.txt"
ABOUT_TXT_FILE="$BRCRAWL_DIR/about.txt"

# Get updated list of feeds
# Order randomly to reduce chances of hammering small providers
sqlite3 "$DB_DIR/database.db" "SELECT feed_url FROM feeds WHERE status_id IN (1, 2) ORDER BY RANDOM();" > "$FEEDS_TXT_FILE"

echo "[$(date +"%Y-%m-%d %H:%M:%S")]: Generated feeds.txt with $(wc -l $FEEDS_TXT_FILE) feeds"

# Update the about.txt page with latest indexed feeds
yesterday_run=$(date +"%Y-%m-%d %H:%M:%S" --date='TZ="UTC" yesterday')
new_feeds=$(($(sqlite3 "$DB_DIR/database.db" "SELECT COUNT(*) FROM feeds WHERE status_id = 2 AND created_at >= '$yesterday_run';") + 0))

if [[ $new_feeds -gt 0 ]]; then
    echo "<li>$(date +"%d/%m/%Y"): +$new_feeds blogs encontrados</li>" >> "$ABOUT_TXT_FILE"
fi

cd "$BRCRAWL_DIR"
./build.sh "$FEEDS_TXT_FILE"

echo "[$(date +"%Y-%m-%d %H:%M:%S")]: Completed build.sh script"
ls *.html

## Remove all html files from current deployment
rm "$WEBSITE_DIR"/content/brcrawl/*.html
mv *.html "$WEBSITE_DIR/content/brcrawl/"

cd "$WEBSITE_DIR"
$HUGO

echo "[$(date +"%Y-%m-%d %H:%M:%S")]: Built guilhermegarcia.dev with hugo"
git status

git add content/brcrawl
git add public/brcrawl
git commit -m "update brcrawl"
git pull --rebase
git push

echo "[$(date +"%Y-%m-%d %H:%M:%S")]: Pushed to github remote. Exiting."
exit 0
