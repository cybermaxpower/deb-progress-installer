#!/bin/bash

# Ensure a file was passed
if [ -z "$1" ]; then
    zenity --error --title="DEB Installer" --text="No installation file provided." --width=300
    exit 1
fi

DEB_FILE="$1"
APP_NAME=$(basename "$DEB_FILE")

# 1. PRE-INSTALL DEPENDENCY CHECK
DEPENDENCIES=$(apt-get install -s "$DEB_FILE" 2>/dev/null | grep "^Inst " | awk '{print $2}' | grep -v "$APP_NAME")

if [ ! -z "$DEPENDENCIES" ]; then
    FORMATTED_LIST=$(echo "$DEPENDENCIES" | sed 's/^/ • /')
    
    zenity --question \
        --title="Additional Dependencies Required" \
        --text="To install <b>$APP_NAME</b>, the system also needs to download and install these required components:\n\n$FORMATTED_LIST\n\nDo you want to proceed?" \
        --width=400
        
    if [ $? -ne 0 ]; then
        exit 0
    fi
fi

# 2. ACTUAL INSTALLATION & PIPED GRAPHICAL UI
RAW_ERROR_LOG=$(mktemp)

(
echo "0"
echo "# Initialising and authenticating..."
sleep 0.5

# Run apt-get and stream everything through a single, stable processing block
pkexec apt-get install -y "$DEB_FILE" -o APT::Status-Fd=3 3>&1 2>"$RAW_ERROR_LOG" | while read -r line; do
    
    # Track online downloads
    if [[ "$line" == *"Get:"* ]]; then
        FETCHING_APP=$(echo "$line" | awk '{print $4}')
        echo "25"
        echo "# Downloading required system component: $FETCHING_APP..."
        
    # Track localized installation progress
    elif [[ "$line" =~ ^([^:]+):([^:]+):([0-9.]+):(.*)$ ]]; then
        PERCENT="${BASH_REMATCH[3]}"
        STATUS_TEXT="${BASH_REMATCH[4]}"
        
        if [[ "$STATUS_TEXT" == *"Preparing"* ]]; then
            STATUS_TEXT="Preparing installation files..."
        elif [[ "$STATUS_TEXT" == *"Unpacking"* ]]; then
            STATUS_TEXT="Extracting and copying application files..."
        elif [[ "$STATUS_TEXT" == *"Running dpkg"* ]]; then
            STATUS_TEXT="Configuring system shortcuts and permissions..."
        fi

        ROUNDED_PCT=$(printf "%.0f" "$PERCENT")
        
        # Scale percentage (30% to 100%) to smoothly account for download history
        SCALED_PCT=$(( 30 + (ROUNDED_PCT * 70 / 100) ))
        echo "$SCALED_PCT"
        echo "# $STATUS_TEXT ($ROUNDED_PCT%)"
    fi
done
) | zenity --progress \
    --title="Installing Software" \
    --text="Starting installer..." \
    --percentage=0 \
    --auto-close \
    --no-cancel \
    --width=470

# 3. RELIABLE ERROR LOGGING EVALUATION
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    rm -f "$RAW_ERROR_LOG"
    zenity --info --title="Success" --text="$APP_NAME installed successfully!" --width=300
else
    ERROR_TEXT=$(cat "$RAW_ERROR_LOG")
    rm -f "$RAW_ERROR_LOG"

    FRIENDLY_ERROR="The installation encountered an unexpected problem."
    SPECIFIC_DETAILS=""

    if [[ "$ERROR_TEXT" == *"Could not get lock"* || "$ERROR_TEXT" == *"dpkg was interrupted"* ]]; then
        FRIENDLY_ERROR="Another software update is currently running in the background. Please wait a minute and try again."
    elif [[ "$ERROR_TEXT" == *"Could not resolve"* || "$ERROR_TEXT" == *"Failed to fetch"* || "$ERROR_TEXT" == *"Size mismatch"* ]]; then
        FRIENDLY_ERROR="Could not download the required dependencies. Please check your internet network connection and try again."
    elif [[ "$ERROR_TEXT" == *"Permission denied"* || "$ERROR_TEXT" == *"Authentication failed"* ]]; then
        FRIENDLY_ERROR="The installation was cancelled because the administrator password was not entered correctly."
    else
        CLEANED_LINE=$(echo "$ERROR_TEXT" | grep -E "E:|dpkg:" | tail -n 1 | sed 's/E: //g')
        if [ ! -z "$CLEANED_LINE" ]; then
            SPECIFIC_DETAILS="\n\n<b>System Report:</b>\n<i>$CLEANED_LINE</i>"
        fi
    fi

    zenity --error \
        --title="Installation Failed" \
        --text="$FRIENDLY_ERROR$SPECIFIC_DETAILS" \
        --width=420
fi
