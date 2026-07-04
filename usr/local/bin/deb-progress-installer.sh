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

# Create temporary logs to safely audit the simulation
SIM_OUT_LOG=$(mktemp)
SIM_ERR_LOG=$(mktemp)

apt-get install -s "$DEB_FILE" >"$SIM_OUT_LOG" 2> >(grep -v -E "NOTE: This is only a simulation|apt-get needs root privileges|Keep also in mind that locking is deactivated|so don't depend on the relevance" > "$SIM_ERR_LOG")
SIM_EXIT_CODE=$?

# If there is a genuine error left over after filtering the banner noise out
if [ $SIM_EXIT_CODE -ne 0 ] && [ -s "$SIM_ERR_LOG" ]; then
    REAL_ERROR=$(cat "$SIM_ERR_LOG" | grep -E "E:|Error:" | tail -n 1)
    zenity --error \
        --title="Dependency Simulation Failed" \
        --text="The system cannot calculate dependencies for <b>$APP_NAME</b>.\n\n<b>Details:</b>\n<i>${REAL_ERROR:-Package architecture or components are incompatible.}</i>" \
        --width=420
    rm -f "$SIM_OUT_LOG" "$SIM_ERR_LOG"
    exit 1
fi

# Parse the clean simulation log for true missing dependencies
DEPENDENCIES=$(cat "$SIM_OUT_LOG" | grep "^Inst " | awk '{print $2}' | grep -v -x "$INTERNAL_PKG_NAME")
rm -f "$SIM_OUT_LOG" "$SIM_ERR_LOG"

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
# 2. STATE DETECTION (Install vs Reinstall vs Remove)
# ==========================================
dpkg-query -W -f='${Status}' "$INTERNAL_PKG_NAME" 2>/dev/null | grep -q "ok installed"
ALREADY_INSTALLED=$?

ACTION=""
if [ $ALREADY_INSTALLED -eq 0 ]; then
    # The app exists! Ask the user to choose an action.
    ACTION=$(zenity --list \
        --title="Manage $INTERNAL_PKG_NAME" \
        --text="<b>$APP_NAME</b> is already installed on your system.\nWhat would you like to do?" \
        --radiolist \
        --column="Select" --column="Action" \
        TRUE "Reinstall the application" \
        FALSE "Remove (Uninstall) the application" \
        --width=400 --height=220)
        
    if [ $? -ne 0 ]; then
        exit 0
    fi
fi

# Configure titles, text, and the specific apt command based on user selection
RAW_ERROR_LOG=$(mktemp)

if [ "$ACTION" = "Remove (Uninstall) the application" ]; then
    TITLE_TEXT="Uninstalling Software"
    START_TEXT="Authenticating and removing application..."
    SUCCESS_TEXT="<b>$INTERNAL_PKG_NAME</b> uninstalled successfully!"
    
    # The REMOVE execution line (uses package name, not file path)
    APT_CMD="pkexec apt-get purge -y $INTERNAL_PKG_NAME -o APT::Status-Fd=3"
elif [ "$ACTION" = "Reinstall the application" ]; then
    TITLE_TEXT="Reinstalling Software"
    START_TEXT="Authenticating and restarting installer..."
    SUCCESS_TEXT="<b>$INTERNAL_PKG_NAME</b> reinstalled successfully!"
    
    # The REINSTALL execution line (adds --reinstall flag)
    APT_CMD="pkexec apt-get install -y --reinstall $DEB_FILE -o APT::Status-Fd=3"
else
    TITLE_TEXT="Installing Software"
    START_TEXT="Authenticating and starting installer..."
    SUCCESS_TEXT="<b>$INTERNAL_PKG_NAME</b> installed successfully!"
    
    # The standard FRESH INSTALL execution line
    APT_CMD="pkexec apt-get install -y $DEB_FILE -o APT::Status-Fd=3"
fi

# ==========================================
# 3. REAL-TIME STREAMING PIPELINE
# ==========================================
$APT_CMD 3>&1 2>"$RAW_ERROR_LOG" | while read -r line; do
    if [[ "$line" == *"Get:"* ]]; then
        FETCHING_APP=$(echo "$line" | awk '{print $4}')
        echo "25"
        echo "# Downloading required components: $FETCHING_APP..."
    elif [[ "$line" =~ ^([^:]+):([^:]+):([0-9.]+):(.*)$ ]]; then
        PERCENT="${BASH_REMATCH[3]}"
        STATUS_TEXT="${BASH_REMATCH[4]}"
        
        # Translate technical jargon to friendly strings
        if [[ "$STATUS_TEXT" == *"Preparing"* ]]; then
            STATUS_TEXT="Preparing files..."
        elif [[ "$STATUS_TEXT" == *"Unpacking"* ]]; then
            STATUS_TEXT="Extracting application files..."
        elif [[ "$STATUS_TEXT" == *"Removing"* ]]; then
            STATUS_TEXT="Removing application files..."
        elif [[ "$STATUS_TEXT" == *"Running dpkg"* ]]; then
            STATUS_TEXT="Configuring system settings..."
        fi

        ROUNDED_PCT=$(printf "%.0f" "$PERCENT")
        # Scale progress elegantly from 30% to 100%
        SCALED_PCT=$(( 30 + (ROUNDED_PCT * 70 / 100) ))
        echo "$SCALED_PCT"
        echo "# $STATUS_TEXT ($ROUNDED_PCT%)"
    fi
done | zenity --progress \
    --title="$TITLE_TEXT" \
    --text="$START_TEXT" \
    --percentage=0 \
    --auto-close \
    --no-cancel \
    --width=470

INSTALL_EXIT_STATUS=${PIPESTATUS[0]}

# ==========================================
# 4. CANCELLATION & SYSTEM ERROR CHECK
# ==========================================
ERROR_TEXT=$(cat "$RAW_ERROR_LOG")
rm -f "$RAW_ERROR_LOG"

if [ $INSTALL_EXIT_STATUS -ne 0 ]; then
    if [[ -z "$ERROR_TEXT" ]] || [[ "$ERROR_TEXT" == *"Request dismissed"* || "$ERROR_TEXT" == *"was cancelled"* || "$ERROR_TEXT" == *"Authentication failed"* || "$ERROR_TEXT" == *"Permission denied"* ]]; then
        zenity --info \
            --title="Operation Cancelled" \
            --text="The operation on <b>$APP_NAME</b> was stopped because administrative permissions were not granted." \
            --width=420
        exit 0
    fi
fi

# ==========================================
# 5. FINAL REGISTRY AUDIT (Success Check)
# ==========================================
dpkg-query -W -f='${Status}' "$INTERNAL_PKG_NAME" 2>/dev/null | grep -q "ok installed"
IS_PRESENT=$?

if [ "$ACTION" = "Remove (Uninstall) the application" ]; then
    # For removal, success means the application is no longer found in the registry
    if [ $IS_PRESENT -ne 0 ]; then
        zenity --info --title="Success" --text="$SUCCESS_TEXT" --width=300
        exit 0
    fi
else
    # For install/reinstall, success means the package is found in the registry
    if [ $IS_PRESENT -eq 0 ]; then
        zenity --info --title="Success" --text="$SUCCESS_TEXT" --width=300
        exit 0
    fi
fi

# Handle unexpected execution errors
FRIENDLY_ERROR="The system encountered an error while processing the package changes."
CLEANED_LINE=$(echo "$ERROR_TEXT" | grep -E "E:|dpkg:" | tail -n 1 | sed 's/E: //g')
if [ ! -z "$CLEANED_LINE" ]; then
    SPECIFIC_DETAILS="\n\n<b>System Report:</b>\n<i>$CLEANED_LINE</i>"
fi

zenity --error --title="Operation Failed" --text="$FRIENDLY_ERROR$SPECIFIC_DETAILS" --width=420
exit 1
