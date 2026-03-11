#!/bin/bash

# Creates a backup of the database and sends to google drive
# this script needs rclone installed

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

if ! rclone --version > /dev/null 2>&1; then
	echo "rclone not found";
	exit 1;
fi

printf -v CUR_DAY '%(%Y-%m-%d)T\n' -1
RUNS_DIR="/home/ubuntu/brcrawl/runs"
DRIVE_URL="https://drive.google.com/drive/folders/115NLKZEoSb4WIUmPIVJrEMUIKwTZSy0W"
ZIP_FILE="$CUR_DAY.zip"

if ! find "$RUNS_DIR" -type d -mtime +1 -exec zip -r "$ZIP_FILE" "{}" +; then
    echo "Couldn't create zip file. Aborting."
    exit 1
fi

echo "Created <$ZIP_FILE>"

if ! rclone sync "$ZIP_FILE" google-drive:/runs; then
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

echo "Deleted directories. Script completed successfully."
rm "$ZIP_FILE"
