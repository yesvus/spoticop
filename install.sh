#!/bin/sh
set -eu

PROG="spoticop"
BIN_SRC="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/spoticop"

if [ ! -f "$BIN_SRC" ]; then
  echo "Error: $BIN_SRC not found." >&2
  exit 1
fi

DEST_DIR="/usr/local/bin"
if [ ! -w "$DEST_DIR" ] && [ "$(id -u)" -ne 0 ]; then
  DEST_DIR="$HOME/.local/bin"
fi

mkdir -p "$DEST_DIR"
cp "$BIN_SRC" "$DEST_DIR/$PROG"
chmod +x "$DEST_DIR/$PROG"
echo "Installed $PROG to $DEST_DIR/$PROG"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/spoticop"
CONFIG_FILE="$CONFIG_DIR/config"
if [ ! -f "$CONFIG_FILE" ]; then
  mkdir -p "$CONFIG_DIR"
  cat <<'EOF' >"$CONFIG_FILE"
# spoticop configuration
CAP = 1GB
DRY_RUN = 0
LOG = ~/Library/Logs/spoticop.log
DAY = Sunday
TIME = 04:00
EOF
  echo "Created default config at $CONFIG_FILE"
fi

if [ "$(uname)" = "Darwin" ]; then
  AGENT_DIR="$HOME/Library/LaunchAgents"
  PLIST="$AGENT_DIR/com.yesvus.spoticop.plist"
  mkdir -p "$AGENT_DIR"

  cat <<EOF >"$PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yesvus.spoticop</string>
    <key>ProgramArguments</key>
    <array>
        <string>$DEST_DIR/$PROG</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>4</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/spoticop.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/spoticop.log</string>
</dict>
</plist>
EOF

  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST" 2>/dev/null || true
  echo "Registered launchd agent at $PLIST"
fi

echo "Installation complete. Run '$PROG --help' for usage."
