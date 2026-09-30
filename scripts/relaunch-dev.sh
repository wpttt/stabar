#!/bin/zsh
# Build StaBar, make sure the running app is the freshly built one, and report proof.
set -e

cd /Users/wpt/GitHub/stabar
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

echo "==> building (Debug)…"
"$DEVELOPER_DIR/usr/bin/xcodebuild" -project StaBar.xcodeproj -scheme StaBar \
  -configuration Debug -destination 'platform=macOS' build 2>&1 \
  | grep -E "error:|warning: .*Swift|BUILD" | tail -5

APP="$HOME/Library/Developer/Xcode/DerivedData/StaBar-ckgxwcpwcyemrmabcjxjdgovjiyw/Build/Products/Debug/StaBar.app"
BIN="$APP/Contents/MacOS/StaBar"
BIN_MTIME=$(stat -f '%Sm' -t '%H:%M:%S' "$BIN")

echo "==> stopping any running instance…"
for pid in $(pgrep -x StaBar); do
  ppid=$(ps -o ppid= -p "$pid" | tr -d ' ')
  parent=$(ps -o comm= -p "$ppid" 2>/dev/null || true)
  if [[ "$parent" == *debugserver* ]]; then
    echo "    (pid $pid is hosted by debugserver $ppid — stopping the debugger too)"
    kill -9 "$ppid" 2>/dev/null || true
  fi
  kill -9 "$pid" 2>/dev/null || true
done
sleep 1.5

echo "==> launching $BIN"
open "$APP"
sleep 3

PID=$(pgrep -x StaBar | head -1)
if [[ -z "$PID" ]]; then
  echo "!! app failed to start"
  exit 1
fi

START=$(ps -o lstart= -p "$PID" | sed 's/^ *//')
START_CLOCK=$(ps -o lstart= -p "$PID" | awk '{print $4}')
echo "--------------------------------------------------"
echo "binary built at : $BIN_MTIME"
echo "app started at  : $START"
echo "pid             : $PID"
if [[ "$START_CLOCK" > "$BIN_MTIME" ]]; then
  echo "status          : ✅ running the LATEST build"
else
  echo "status          : ❌ app looks older than the binary — restart failed"
fi
echo "--------------------------------------------------"
