#!/bin/bash

# Ensure Zenity plays nicely with both Wayland and X11
export GDK_BACKEND=wayland,x11

# Use the classic 2D Cairo engine (vastly faster than 'software' 3D emulation on the CPU)
export GSK_RENDERER=cairo

# FORCE background terminal utilities to output in English 
# This prevents localized systems (e.g., Russian, French) from breaking the dependency parser
export LC_ALL=C

# ==========================================
# RUNTIME GTK4 TRANSPARENCY PATCH (SANDBOX)
# ==========================================
# Create a secure temporary configuration environment
GTK_SANDBOX=$(mktemp -d -t deb-installer-sandbox.XXXXXX)
mkdir -p "$GTK_SANDBOX/gtk-4.0"

# Automatically clean up the temporary sandbox directory when the script exits
trap 'rm -rf "$GTK_SANDBOX"' EXIT

# Inherit the user's existing custom CSS modifications if they have any
if [ -f "$HOME/.config/gtk-4.0/gtk.css" ]; then
    cp "$HOME/.config/gtk-4.0/gtk.css" "$GTK_SANDBOX/gtk-4.0/gtk.css"
fi

# Append the precise target selectors to force solid background rendering
# without breaking child component layouts or hardcoding specific colors
cat << 'EOF' >> "$GTK_SANDBOX/gtk-4.0/gtk.css"
window, dialog, .background, main, box.vertical {
    background-color: @window_bg_color;
    opacity: 1.0;
}
EOF

# Ensure an installation file was passed
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

# Parse the simulation log for true missing dependencies
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
    # Clean size scaling preventing text row clipping and ensuring rendering stability
    ACTION=$(zenity --list \
        --title="Manage $INTERNAL_PKG_NAME" \
        --text="<b>$APP_NAME</b> is already installed on your system.\nWhat would you like to do?" \
        --radiolist \
        --column="Select" --column="Action" \
        TRUE "Reinstall the application" \
        FALSE "Remove (Uninstall) the application" \
        --width=480 --height=320)
        
    # If they click Cancel or close the window, exit gracefully
    if [ $? -ne 0 ]; then
        exit 0
    fi
fi

# ==========================================
# 3. RUN OPERATION IN BACKGROUND
# ==========================================
APT_STATUS_LOG=$(mktemp)
RAW_ERROR_LOG=$(mktemp)

if [ "$ACTION" = "Remove (Uninstall) the application" ]; then
    TITLE_TEXT="Uninstalling Software"
    START_TEXT="Authenticating and removing application..."
    APT_CMD="pkexec apt-get purge -y $INTERNAL_PKG_NAME -o APT::Status-Fd=3"
elif [ "$ACTION" = "Reinstall the application" ]; then
    TITLE_TEXT="Reinstalling Software"
    START_TEXT="Authenticating and restarting installer..."
    APT_CMD="pkexec apt-get install -y --reinstall $DEB_FILE -o APT::Status-Fd=3"
else
    TITLE_TEXT="Installing Software"
    START_TEXT="Authenticating and starting installer..."
    APT_CMD="pkexec apt-get install -y $DEB_FILE -o APT::Status-Fd=3"
fi

# Start execution engine in background
$APT_CMD 3>"$APT_STATUS_LOG" 2>"$RAW_ERROR_LOG" &
INSTALL_PID=$!

# ==========================================
# 4. LIVE PROGRESS TRACKING LOOP
# ==========================================
(
echo "0"
echo "# Preparing runtime pipeline..."

while kill -0 $INSTALL_PID 2>/dev/null; do
    if [ -s "$APT_STATUS_LOG" ]; then
        LATEST_LINE=$(tail -n 1 "$APT_STATUS_LOG")
        
        if [[ "$LATEST_LINE" == *"Get:"* ]]; then
            FETCHING_APP=$(echo "$LATEST_LINE" | awk '{print $4}')
            echo "25"
            echo "# Downloading: $FETCHING_APP..."
        elif [[ "$LATEST_LINE" =~ ^([^:]+):([^:]+):([0-9.]+):(.*)$ ]]; then
            PERCENT="${BASH_REMATCH[3]}"
            STATUS_TEXT="${BASH_REMATCH[4]}"
            
            if [[ "$STATUS_TEXT" == *"Preparing"* ]]; then
                STATUS_TEXT="Preparing files..."
            elif [[ "$STATUS_TEXT" == *"Unpacking"* ]]; then
                STATUS_TEXT="Extracting application files..."
            elif [[ "$STATUS_TEXT" == *"Running dpkg"* ]]; then
                STATUS_TEXT="Configuring system shortcuts..."
            fi

            ROUNDED_PCT=$(printf "%.0f" "$PERCENT")
            SCALED_PCT=$(( 30 + (ROUNDED_PCT * 70 / 100) ))
            
            echo "$SCALED_PCT"
            echo "# $STATUS_TEXT ($ROUNDED_PCT%)"
        fi
    fi
    sleep 0.1
done

echo "100"
echo "# Finalising system registration..."
) | zenity --progress \
    --title="$TITLE_TEXT" \
    --text="$START_TEXT" \
    --percentage=0 \
    --auto-close \
    --no-cancel \
    --width=470

wait $INSTALL_PID
INSTALL_EXIT_STATUS=$?

# ==========================================
# 5. VERIFICATION & CANCELLATION CHECK
# ==========================================
ERROR_TEXT=$(cat "$RAW_ERROR_LOG")
rm -f "$RAW_ERROR_LOG"
rm -f "$APT_STATUS_LOG"

if [ $INSTALL_EXIT_STATUS -ne 0 ]; then
    if [[ -z "$ERROR_TEXT" ]] || [[ "$ERROR_TEXT" == *"Request dismissed"* || "$ERROR_TEXT" == *"was cancelled"* || "$ERROR_TEXT" == *"Authentication failed"* || "$ERROR_TEXT" == *"Permission denied"* ]]; then
        zenity --info \
            --title="Operation Cancelled" \
            --text="The operation on <b>$APP_NAME</b> was stopped because administrative permissions were not granted.\n\nNo changes were made to your system." \
            --width=420
        exit 0
    fi
fi

# ==========================================
# 6. FINAL SANITY CHECK (Success Notification)
# ==========================================
dpkg-query -W -f='${Status}' "$INTERNAL_PKG_NAME" 2>/dev/null | grep -q "installed"
IS_PRESENT=$?

if [ "$ACTION" = "Remove (Uninstall) the application" ]; then
    if [ $IS_PRESENT -ne 0 ]; then
        zenity --info --title="Success" --text="<b>$INTERNAL_PKG_NAME</b> uninstalled successfully!" --width=300
        exit 0
    fi
else
    if [ $IS_PRESENT -eq 0 ]; then
        zenity --info --title="Success" --text="<b>$INTERNAL_PKG_NAME</b> installed successfully!" --width=300
        exit 0
    fi
fi

FRIENDLY_ERROR="The installer encountered an issue modifying the package state."
SPECIFIC_DETAILS=""

if [[ "$ERROR_TEXT" == *"Could not get lock"* || "$ERROR_TEXT" == *"dpkg was interrupted"* ]]; then
    FRIENDLY_ERROR="Another software update is currently running in the background. Please wait a minute and try again."
elif [[ "$ERROR_TEXT" == *"Could not resolve"* || "$ERROR_TEXT" == *"Failed to fetch"* ]]; then
    FRIENDLY_ERROR="Could not download required dependencies. Please check your network connection and try again."
else
    CLEANED_LINE=$(echo "$ERROR_TEXT" | grep -E "E:|dpkg:" | tail -n 1 | sed 's/E: //g')
    if [ ! -z "$CLEANED_LINE" ]; then
        SPECIFIC_DETAILS="\n\n<b>System Report:</b>\n<i>$CLEANED_LINE</i>"
    fi
fi

zenity --error --title="Operation Failed" --text="$FRIENDLY_ERROR$SPECIFIC_DETAILS" --width=420
exit 1
