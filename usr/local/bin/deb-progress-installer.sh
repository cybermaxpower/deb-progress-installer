#!/bin/bash

# Ensure Zenity plays nicely with both Wayland and X11
export GDK_BACKEND=wayland,x11

# Ensure a file was passed
if [ -z "$1" ]; then
    zenity --error --title="DEB Installer" --text="No installation file provided." --width=300
    exit 1
fi

DEB_FILE="$1"
APP_NAME=$(basename "$DEB_FILE")

# ==========================================
# 1. PRE-INSTALL DEPENDENCY CHECK
# ==========================================
INTERNAL_PKG_NAME=$(dpkg-deb -f "$DEB_FILE" Package 2>/dev/null)
if [ -z "$INTERNAL_PKG_NAME" ]; then
    INTERNAL_PKG_NAME=$(basename "$DEB_FILE" .deb | cut -d'_' -f1)
fi

DEPENDENCIES=$(apt-get install -s "$DEB_FILE" 2>/dev/null | grep "^Inst " | awk '{print $2}' | grep -v -x "$INTERNAL_PKG_NAME")

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

# ==========================================
# 2. RUN INSTALLATION IN BACKGROUND
# ==========================================
APT_STATUS_LOG=$(mktemp)
RAW_ERROR_LOG=$(mktemp)

# Start the installer in the background so the UI loop can read it live
pkexec apt-get install -y "$DEB_FILE" -o APT::Status-Fd=3 3>"$APT_STATUS_LOG" 2>"$RAW_ERROR_LOG" &
INSTALL_PID=$!

# ==========================================
# 3. LIVE PROGRESS TRACKING LOOP
# ==========================================
(
echo "0"
echo "# Preparing installation framework..."

# Loop continuously while the background apt-get process is alive
while kill -0 $INSTALL_PID 2>/dev/null; do
    if [ -s "$APT_STATUS_LOG" ]; then
        # Snatch the very last status update line written by apt
        LATEST_LINE=$(tail -n 1 "$APT_STATUS_LOG")
        
        if [[ "$LATEST_LINE" == *"Get:"* ]]; then
            FETCHING_APP=$(echo "$LATEST_LINE" | awk '{print $4}')
            echo "25"
            echo "# Downloading: $FETCHING_APP..."
        elif [[ "$LATEST_LINE" =~ ^([^:]+):([^:]+):([0-9.]+):(.*)$ ]]; then
            PERCENT="${BASH_REMATCH[3]}"
            STATUS_TEXT="${BASH_REMATCH[4]}"
            
            # Translate raw statuses to human-friendly strings
            if [[ "$STATUS_TEXT" == *"Preparing"* ]]; then
                STATUS_TEXT="Preparing files..."
            elif [[ "$STATUS_TEXT" == *"Unpacking"* ]]; then
                STATUS_TEXT="Extracting application files..."
            elif [[ "$STATUS_TEXT" == *"Running dpkg"* ]]; then
                STATUS_TEXT="Configuring system shortcuts..."
            fi

            # Scale percentages safely (30% to 100%) so the bar climbs smoothly
            ROUNDED_PCT=$(printf "%.0f" "$PERCENT")
            SCALED_PCT=$(( 30 + (ROUNDED_PCT * 70 / 100) ))
            
            echo "$SCALED_PCT"
            echo "# $STATUS_TEXT ($ROUNDED_PCT%)"
        fi
    fi
    sleep 0.1 # High frequency refresh rate for ultra-smooth rendering
done

echo "100"
echo "# Finalising registration..."
) | zenity --progress \
    --title="Installing Software" \
    --text="Authenticating..." \
    --percentage=0 \
    --auto-close \
    --no-cancel \
    --width=470

# Wait for the background process to officially close out and collect its final exit status
wait $INSTALL_PID
INSTALL_EXIT_STATUS=$?

# ==========================================
# 4. VERIFICATION & CANCELLATION CHECK
# ==========================================
ERROR_TEXT=$(cat "$RAW_ERROR_LOG")
rm -f "$RAW_ERROR_LOG"
rm -f "$APT_STATUS_LOG"

if [ $INSTALL_EXIT_STATUS -ne 0 ]; then
    if [[ -z "$ERROR_TEXT" ]] || [[ "$ERROR_TEXT" == *"Request dismissed"* || "$ERROR_TEXT" == *"was cancelled"* || "$ERROR_TEXT" == *"Authentication failed"* || "$ERROR_TEXT" == *"Permission denied"* ]]; then
        zenity --info \
            --title="Installation Cancelled" \
            --text="The installation of <b>$APP_NAME</b> was stopped because administrative permissions were not granted.\n\nNo changes were made to your system." \
            --width=420
        exit 0
    fi
fi

# ==========================================
# 5. FINAL SANITY CHECK (Success Notification)
# ==========================================
dpkg-query -W -f='${Status}' "$INTERNAL_PKG_NAME" 2>/dev/null | grep -q "installed"
if [ $? -eq 0 ]; then
    zenity --info --title="Success" --text="<b>$INTERNAL_PKG_NAME</b> installed successfully!" --width=300
    exit 0
else
    FRIENDLY_ERROR="The installer encountered an issue while setting up the software."
    SPECIFIC_DETAILS=""

    if [[ "$ERROR_TEXT" == *"Could not get lock"* || "$ERROR_TEXT" == *"dpkg was interrupted"* ]]; then
        FRIENDLY_ERROR="Another software update is currently running in the background. Please wait a minute and try again."
    elif [[ "$ERROR_TEXT" == *"Could not resolve"* || "$ERROR_TEXT" == *"Failed to fetch"* ]]; then
        FRIENDLY_ERROR="Could not download the required dependencies. Please check your internet connection and try again."
    else
        CLEANED_LINE=$(echo "$ERROR_TEXT" | grep -E "E:|dpkg:" | tail -n 1 | sed 's/E: //g')
        if [ ! -z "$CLEANED_LINE" ]; then
            SPECIFIC_DETAILS="\n\n<b>System Report:</b>\n<i>$CLEANED_LINE</i>"
        fi
    fi

    zenity --error --title="Installation Failed" --text="$FRIENDLY_ERROR$SPECIFIC_DETAILS" --width=420
    exit 1
fi
