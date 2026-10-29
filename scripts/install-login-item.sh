#!/bin/bash
# Install co-awake as a per-user login item via a LaunchAgent.
#
# Personal-use auto-start: no root, no packaging, no .app bundle. The entire
# footprint is one plist in ~/Library/LaunchAgents/, fully reversed by
# scripts/uninstall-login-item.sh.
#
# Any extra args are baked into the login item (--preset, --load-source, etc.):
#   ./scripts/install-login-item.sh
#   ./scripts/install-login-item.sh --preset horse-black --load-source memory
#   ./scripts/install-login-item.sh --keep-awake 4h        # arm Keep Awake at every login
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
LOG_DIR="$HOME/Library/Logs"
LOG="$LOG_DIR/co-awake.log"
DOMAIN="gui/$(id -u)"

# Resolve this script's real directory (following symlinks) -> repo root -> launcher + binary.
src="${BASH_SOURCE[0]}"
while [ -h "$src" ]; do
  dir="$(cd -P "$(dirname "$src")" && pwd)"
  src="$(readlink "$src")"
  [[ "$src" != /* ]] && src="$dir/$src"
done
SCRIPT_DIR="$(cd -P "$(dirname "$src")" && pwd)"
REPO_DIR="$(cd -P "$SCRIPT_DIR/.." && pwd)"
LAUNCHER="$REPO_DIR/awake"
BINARY="$REPO_DIR/CoAwake"

[ -x "$LAUNCHER" ] || { echo "error: launcher not found or not executable: $LAUNCHER" >&2; exit 1; }

# Ensure the compiled Mach-O binary is current before registering. Through the launcher's `build`,
# which owns the build + ad-hoc codesign (`com.binle.coawake`) and renames the new binary into place
# rather than writing over it, so a reinstall while an instance is running can't corrupt the process
# paging out of it.
echo "Pre-building binary…"
"$LAUNCHER" build
[ -x "$BINARY" ] || { echo "error: compiled binary not found or not executable: $BINARY" >&2; exit 1; }

# ProgramArguments: launchd supervises the compiled Mach-O binary `CoAwake` directly (it always runs
# attached, and carries an ad-hoc code signature `com.binle.coawake` so macOS Background Task
# Management and EDR scanners verify it as a signed native binary rather than an unsigned shell script).
# CO_AWAKE_LAUNCHER / CO_AWAKE_LAUNCH_MODE in EnvironmentVariables preserve the in-app self-updater's
# ability to invoke `awake build`.
xml_escape(){ local s="$1"; s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"; printf '%s' "$s"; }
prog=""
passthrough=()
for a in "$@"; do
  [ "$a" = "--foreground" ] && continue
  passthrough+=("$a")
done
for a in "$BINARY" "start" "${passthrough[@]+"${passthrough[@]}"}"; do
  prog+="        <string>$(xml_escape "$a")</string>"$'\n'
done

mkdir -p "$HOME/Library/LaunchAgents" "$LOG_DIR"
plist_content="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
${prog}    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin</string>
        <key>CO_AWAKE_BIN_NAME</key>
        <string>awake</string>
        <key>CO_AWAKE_LAUNCHER</key>
        <string>$(xml_escape "$LAUNCHER")</string>
        <key>CO_AWAKE_LAUNCH_MODE</key>
        <string>attached</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$(xml_escape "$LOG")</string>
    <key>StandardErrorPath</key>
    <string>$(xml_escape "$LOG")</string>
</dict>
</plist>"
# NOTE: no KeepAlive on purpose — choosing Exit from the menu quits it until next login.
# Write via bash builtin printf only when the content actually changed, avoiding unnecessary plist
# modification events and external /bin/cat spawns into ~/Library/LaunchAgents.
if [ ! -f "$PLIST" ] || [ "$(cat "$PLIST" 2>/dev/null || true)" != "$plist_content" ]; then
  printf '%s\n' "$plist_content" > "$PLIST"
fi

# Idempotent (re)load: bootout first so a re-install doesn't hit "service already loaded".
# bootout is asynchronous, so poll until both the old service registration and any supervised
# process from it disappear before re-bootstrapping — otherwise bootstrap races the teardown
# (either failing with 5 "Input/output error", or starting RunAtLoad while the old PID is still
# visible to the launcher's singleton pgrep guard). RunAtLoad=true starts the job on bootstrap;
# a separate `kickstart -k` right after bootstrap would kill the instance bootstrap just started
# and race its own teardown.
old_pid="$(launchctl print "$DOMAIN/$LABEL" 2>/dev/null | awk '/^[[:space:]]*pid = / { print $3; exit }' || true)"
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
for _ in $(seq 1 30); do
  if ! launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1 \
     && { [ -z "$old_pid" ] || ! kill -0 "$old_pid" 2>/dev/null; }; then
    break
  fi
  sleep 0.1
done
launchctl bootstrap "$DOMAIN" "$PLIST"

echo "Installed login item: $LABEL"
echo "  plist:   $PLIST"
echo "  command: $BINARY start ${passthrough[*]+"${passthrough[*]}"}"
echo "  log:     $LOG"
echo "Uninstall: $SCRIPT_DIR/uninstall-login-item.sh"
