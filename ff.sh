#!/bin/bash

# ==================================================
# FUCKINGFAST Upload Script
# Features:
# - Live upload progress
# - Upload speed
# - Upload time
# - Final download link
# - File/folder upload
# ==================================================

API_URL="https://w.fuckingfast.net"
BASE_DOWNLOAD="https://fuckingfast.net"

# Optional token
# Leave empty for anonymous uploads
TOKEN="YOUR_ACCOUNT_ID"

TARGET="$1"
PARENT_ID="$2"

if [ -z "$TARGET" ]; then
    echo "Usage:"
    echo "  ffupload <file_or_folder> [parentId]"
    exit 1
fi

SUCCESS=0
FAILED=0

human_size() {
    numfmt --to=iec-i --suffix=B "$1"
}

upload_file() {
    FILE="$1"
    BASENAME=$(basename "$FILE")

    FILE_SIZE=$(stat -c%s "$FILE")
    HUMAN_FILE_SIZE=$(human_size "$FILE_SIZE")

    echo "=================================================="
    echo "Uploading : $BASENAME"
    echo "Size      : $HUMAN_FILE_SIZE"
    echo "=================================================="

    if [ -n "$PARENT_ID" ]; then
        URL="$API_URL/$PARENT_ID/$BASENAME"

        RESPONSE=$(curl \
            -T "$FILE" \
            -H "Authorization: Bearer $TOKEN" \
            "$URL" \
            --progress-bar \
            -w "\nUPLOAD_SPEED:%{speed_upload}\nTIME:%{time_total}\n" \
            -o /tmp/ffupload_response.json)
    else
        URL="$API_URL/$BASENAME"

        RESPONSE=$(curl \
            -T "$FILE" \
            "$URL" \
            --progress-bar \
            -w "\nUPLOAD_SPEED:%{speed_upload}\nTIME:%{time_total}\n" \
            -o /tmp/ffupload_response.json)
    fi

    echo

    JSON=$(cat /tmp/ffupload_response.json)

    FILE_ID=$(echo "$JSON" | grep -oP '"id":"\K[^"]+')

    SPEED=$(echo "$RESPONSE" | grep "UPLOAD_SPEED" | cut -d':' -f2)
    TIME_TOTAL=$(echo "$RESPONSE" | grep "TIME" | cut -d':' -f2)

    SPEED_INT=${SPEED%.*}

    [ -z "$SPEED_INT" ] && SPEED_INT=0

    HUMAN_SPEED=$(human_size "$SPEED_INT")

    if [ -n "$FILE_ID" ]; then
        LINK="$BASE_DOWNLOAD/$FILE_ID"

        echo "[✓] Upload completed"
        echo "Speed     : $HUMAN_SPEED/s"
        echo "Time      : ${TIME_TOTAL}s"
        echo "Link      : $LINK"

        SUCCESS=$((SUCCESS + 1))
    else
        echo "[✗] Upload failed"
        echo "$JSON"

        FAILED=$((FAILED + 1))
    fi

    echo
}

# Single file upload
if [ -f "$TARGET" ]; then

    upload_file "$TARGET"

# Folder upload
elif [ -d "$TARGET" ]; then

    TOTAL=$(find "$TARGET" -type f | wc -l)
    COUNT=0

    find "$TARGET" -type f | while read -r FILE; do
        COUNT=$((COUNT + 1))

        echo
        echo "[$COUNT/$TOTAL]"

        upload_file "$FILE"
    done

else
    echo "Invalid path: $TARGET"
    exit 1
fi

echo "=================================================="
echo "Finished"
echo "=================================================="
echo "Successful uploads : $SUCCESS"
echo "Failed uploads     : $FAILED"