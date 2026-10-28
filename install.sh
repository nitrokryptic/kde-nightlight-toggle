#!/bin/bash
# kde-nightlight-toggle installer
# Installs a one-click Night Light toggle for KDE Plasma 6 and makes
# Night Light start switched off on every login.
#
# Usage:
#   bash install.sh              install
#   bash install.sh --uninstall  remove everything this script installed

set -e

BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
AUTO="$HOME/.config/autostart"

TOGGLE="$BIN/nightlight-toggle"
BOOT="$BIN/nightlight-boot-off"
LAUNCHER="$APPS/nightlight-toggle.desktop"
AUTOSTART="$AUTO/nightlight-boot-off.desktop"

if [ "$1" = "--uninstall" ]; then
    rm -f "$TOGGLE" "$BOOT" "$LAUNCHER" "$AUTOSTART"
    command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true
    echo "Removed nightlight-toggle, nightlight-boot-off, the launcher and the autostart entry."
    exit 0
fi

# --- Dependency check ---
missing=0
for cmd in qdbus6 busctl kwriteconfig6; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing required command: $cmd"
        missing=1
    fi
done
if [ "$missing" -eq 1 ]; then
    echo "This installer needs KDE Plasma 6. Aborting."
    exit 1
fi

mkdir -p "$BIN" "$APPS" "$AUTO"

# --- Toggle script ---
cat > "$TOGGLE" <<'EOF'
#!/bin/bash
# Flips KDE Night Light between suspended and active.
qdbus6 org.kde.kglobalaccel /component/kwin invokeShortcut "Toggle Night Color"
EOF
chmod +x "$TOGGLE"

# --- Boot script: suspend Night Light after login if it is running ---
cat > "$BOOT" <<'EOF'
#!/bin/bash
# Runs at login. Waits for KWin, then suspends Night Light if it isn't already.
sleep 8
r=$(busctl --user get-property org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight inhibited)
[ "$r" = "b false" ] && qdbus6 org.kde.kglobalaccel /component/kwin invokeShortcut "Toggle Night Color"
exit 0
EOF
chmod +x "$BOOT"

# --- App launcher (pin this to your panel) ---
cat > "$LAUNCHER" <<EOF
[Desktop Entry]
Type=Application
Name=Night Light Toggle
Exec=$TOGGLE
Icon=redshift-status-on
Terminal=false
Categories=Utility;
EOF

# --- Autostart entry ---
cat > "$AUTOSTART" <<EOF
[Desktop Entry]
Type=Application
Name=Night Light Boot Off
Exec=$BOOT
Terminal=false
EOF

# --- Make sure Night Light itself is enabled so the toggle has something to control ---
kwriteconfig6 --file kwinrc --group NightColor --key Active true

# --- Refresh the app menu ---
command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true

echo "Installed."
echo
echo "Next steps:"
echo "  1. Open the app launcher, search 'Night Light Toggle', right-click it and choose 'Pin to Task Manager'."
echo "  2. Test it:  $TOGGLE"
echo "  3. Reboot. You should land with Night Light off."
