#!/bin/bash

# Ensure a file was passed
if [ -z "$1" ]; then
    zenity --error --text="No .deb file specified." --title="Error" 2>/dev/null
    exit 1
fi

DEB_FILE="$1"
FILE_NAME=$(basename "$DEB_FILE")

# Run apt-get inside pkexec, and pipe its progress into zenity
(
pkexec apt-get install -y "$DEB_FILE" -o APT::Status-Fd=3 3>&1 >&2 | while read -r line; do
    if [[ "$line" =~ ^([^:]+):([^:]+):([0-9.]+):(.*)$ ]]; then
        PERCENT="${BASH_REMATCH[3]}"
        STATUS_TEXT="${BASH_REMATCH[4]}"
        INT_PERCENT=$(printf "%.0f" "$PERCENT" 2>/dev/null)
        
        echo "$INT_PERCENT"
        echo "# Installing: $STATUS_TEXT ($INT_PERCENT%)"
    fi
done
) | zenity --progress --title="Installing $FILE_NAME" --text="Waiting for authentication..." --percentage=0 --auto-close --width=450 2>/dev/null

# Capture the exit status of the pkexec command
EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    zenity --info --text="$FILE_NAME installed successfully!" --title="Success" --width=300 2>/dev/null
elif [ $EXIT_CODE -eq 126 ] || [ $EXIT_CODE -eq 127 ]; then
    # 126/127 means the user canceled the password prompt
    exit 0
else
    zenity --error --text="Failed to install $FILE_NAME. Make sure dependencies are met." --title="Installation Failed" --width=300 2>/dev/null
fi
