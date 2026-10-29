#!/bin/bash
# Remove the co-awake login item — the exact inverse of install-login-item.sh:
# deregister the LaunchAgent, then delete its plist and log. No root, no residue
# (no receipts DB, no Background Task Management entry). Safe to run repeatedly.
set -euo pipefail

for entry in $(env | grep -E "^CO_AWARENESS_[^=]+=" || true); do
  var="${entry%%=*}"
  val="${entry#*=}"
  if [ -n "$val" ]; then
    echo "error: $var is retired; see --help for current CO_AWAKE_* environment variables." >&2
    exit 1
  fi
done

LABEL="com.binle.coawake"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/co-awake.log"
DOMAIN="gui/$(id -u)"

# bootout reverses bootstrap: stops the supervised process and removes the registration.
# (We never use `launchctl disable`, which would leave a persistent override behind.)
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
rm -f "$PLIST"
rm -f "$LOG" "/tmp/$LABEL.log" "/tmp/co-awake.log"

echo "Removed login item: $LABEL"
echo "  deregistered; plist + log deleted; nothing else was installed."
echo "Note: an instance you launched manually is not affected — stop it with: pkill -f 'CoAwake'"
