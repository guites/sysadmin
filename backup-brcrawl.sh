#!/bin/bash

# Creates a backup of the database and sends to google drive
# this script needs rclone and zip installed

# sudo apt install zip
# curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
# unzip rclone-current-linux-amd64.zip
# cd rclone-*-linux-amd64
# cp rclone /usr/bin/
# chown root:root /usr/bin/rclone
# chmod 755 /usr/bin/rclone

# Follow https://rclone.org/drive/#making-your-own-client-id to set up a google drive client
# and then run `rclone config` to set the client id and secret locally
# use `google-drive` as the remote name

set -e # exit on error
set -u # error on undefined variables

if ! zip --version > /dev/null 2>&1; then
    echo "zip not installed";
    exit 1;
fi

if ! rclone --version > /dev/null 2>&1; then
	echo "rclone not found";
	exit 1;
fi

printf -v CUR_DAY '%(%Y-%m-%d)T' -1
RUNS_DIR="/home/ubuntu/brcrawl/runs"
DRIVE_URL="https://drive.google.com/drive/folders/1oZESH3ryjWPA7dZlt5T8tLL6YC7vmL_-"
ZIP_FILE="$CUR_DAY.zip"

if ! find "$RUNS_DIR" -type d -mtime +1 -exec zip -r "$ZIP_FILE" "{}" +; then
    echo "Couldn't create zip file. Aborting."
    exit 1
fi

echo "Created <$ZIP_FILE>"

if ! rclone sync "$ZIP_FILE" brcrawl:/brcrawl/runs; then
    echo "Error backing up to google drive. Aborting."
    rm "$ZIP_FILE"
    exit 1
fi

echo "Backed up <$ZIP_FILE> over to <$DRIVE_URL>"

if ! find "$RUNS_DIR" -type d -mtime +1 -exec rm -rf "{}" \;; then
    echo "Error deleting directories. Aborting."
    rm "$ZIP_FILE"
    exit 1
fi

echo "Deleted backed up directories."

rm "$ZIP_FILE"

echo "Deleted zip file. Exiting."
