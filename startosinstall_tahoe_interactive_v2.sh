#!/bin/bash

# ==============================================================================
# Revised macOS Erase & Install Script (Manual Download Version)
# Optimized for: macOS 15 (Sequoia) & macOS 26 (Tahoe)
# ==============================================================================

# --- 1. Dynamic Installer Detection ---
echo "------------------------------------------------------------------"
echo "📡 Scanning for local macOS installers in /Applications..."

# Finds any app in /Applications starting with "Install macOS"
INSTALLER_APPS=$(find /Applications -maxdepth 1 -name "Install macOS*" -type d)

# Count found installers
COUNT=$(echo "$INSTALLER_APPS" | grep -c "Install macOS" || true)

if [ "$COUNT" -eq 0 ]; then
    echo "❌ ERROR: No macOS installer found in /Applications."
    echo "   Please download macOS from the App Store or System Settings first."
    exit 1
elif [ "$COUNT" -gt 1 ]; then
    echo "⚠️  Multiple installers found. Please choose one:"
    select APP in $INSTALLER_APPS; do
        if [ -n "$APP" ]; then
            INSTALLER_APP="$APP"
            break
        fi
    done
else
    INSTALLER_APP="$INSTALLER_APPS"
fi

INSTALLER_BIN="$INSTALLER_APP/Contents/Resources/startosinstall"
echo "✅ Using: $INSTALLER_APP"
echo "------------------------------------------------------------------"

# --- 2. System Verification ---
CURRENT_VER=$(sw_vers -productVersion)
echo "💻 Current OS: macOS $CURRENT_VER"

# Space Check (startosinstall usually requires ~45GB free for the process)
FREE_SPACE_GB=$(df -g / | awk 'NR==2 {print $4}')
if [ "$FREE_SPACE_GB" -lt 45 ]; then
    echo "❌ ERROR: Insufficient disk space ($FREE_SPACE_GB GB). 45GB recommended."
    exit 1
fi

# --- 3. Interactive Credentials ---
read -p "👤 Enter Local Admin Username: " ADMIN_USER
if [[ -z "$ADMIN_USER" ]]; then echo "❌ Error: Username required." && exit 1; fi

echo -n "🔑 Enter Admin Password: "
read -s ADMIN_PASS
echo -e "\n------------------------------------------------------------------"

# --- 4. Final Confirmation ---
echo "⚠️  CRITICAL WARNING: THIS WILL PERMANENTLY ERASE ALL DATA."
read -p "🔥 Type 'ERASE' to confirm and begin reinstallation: " FINAL_CONFIRM
if [[ "$FINAL_CONFIRM" != "ERASE" ]]; then echo "Aborted." && exit 0; fi

# --- 5. Execution ---
echo "🚀 Initiating Erase and Install... Do not close the lid."
echo "$ADMIN_PASS" | sudo "$INSTALLER_BIN" \
  --eraseinstall \
  --agreetolicense \
  --forcequitapps \
  --newvolumename "Macintosh HD" \
  --user "$ADMIN_USER" \
  --stdinpass \
  --nointeraction

# --- 6. Post-Execution Check ---
if [ $? -ne 0 ]; then
    echo "❌ FAILED: The process was interrupted or credentials were rejected."
    echo "💡 Note: On Apple Silicon, the user must be a 'Volume Owner'."
    exit 1
fi