#!/usr/bin/env bash
# Real-session e2e: for use INSIDE a graphical GNOME session with the
# extension loaded (i.e. after `./install.sh --enable` and a session start,
# or any time the extension is enabled in the current session).
#
# Clicks the panel button with real injected input (ydotool), presses
# Escape, clicks outside, and captures via the extension's internal
# screenshot API (falls back to GNOME's Print-key screenshot flow).
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh

WORK=/tmp/pqv-real
CAPS="$WORK/captures"
rm -rf "$WORK"; mkdir -p "$CAPS"

FAILED=0
check() {
    if [[ "$2" == "$3" ]]; then echo "PASS: $1 ($2)"; else echo "FAIL: $1 — expected '$2' got '$3'"; FAILED=1; fi
}

# Make sure the extension is installed and enabled in THIS session.
if ! gnome-extensions info "$UUID" >/dev/null 2>&1; then
    ./install.sh --enable >/dev/null
    echo "NOTE: freshly enabled; the running shell only loads new extensions"
    echo "      after a session restart. If the checks below fail with"
    echo "      'not activatable', log out and back in, then re-run."
fi

# save and restore the user's own settings around the run
PREV_DEBUG=$(gsettings get org.gnome.shell.extensions.planify-quick-view debug-dbus)
PREV_KEYBIND=$(gsettings get org.gnome.shell.extensions.planify-quick-view toggle-quick-view)
trap 'gsettings set org.gnome.shell.extensions.planify-quick-view debug-dbus "$PREV_DEBUG";       gsettings set org.gnome.shell.extensions.planify-quick-view toggle-quick-view "$PREV_KEYBIND"' EXIT
gsettings set org.gnome.shell.extensions.planify-quick-view debug-dbus true
sleep 0.5
wait_ext 20 || { echo "FAIL: debug D-Bus did not appear (is the extension loaded in this session?)"; exit 1; }

STATE=$(ext_status)
echo "$STATE"
check "database found (real session)" True "$(echo "$STATE" | python3 -c "import sys,json;print(json.load(sys.stdin)['dbFound'])")"
TASKS=$(echo "$STATE" | python3 -c "import sys,json;print(json.load(sys.stdin)['tasks'])")

BTN=$(echo "$STATE" | python3 -c "
import sys, json
b = json.load(sys.stdin)['button']
print(int(b['x'] + b['w'] / 2), int(b['y'] + b['h'] / 2))")
BX=${BTN%% *}; BY=${BTN##* }

# display scale for ydotool (physical pixels)
SCALE=$(busctl --user -j call org.gnome.Mutter.DisplayConfig /org/gnome/Mutter/DisplayConfig \
    org.gnome.Mutter.DisplayConfig GetCurrentState 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)['data']
entry = d[1][0]
nums = [v for v in entry if isinstance(v, (int, float)) and not isinstance(v, bool)]
print(nums[2] if len(nums) > 2 else 1.0)")
PX=$(python3 -c "print(int($BX * $SCALE))")
PY=$(python3 -c "print(int($BY * $SCALE))")
echo "panel button: stage($BX,$BY) physical($PX,$PY) scale $SCALE"

click_at() { ydotool mousemove -a "$1" "$2"; sleep 0.25; ydotool click 0xC0; }
capture() { # capture <name> — internal API first, Print-key fallback
    ext_capture "$CAPS/$1.png" && { echo "  captured $1 (internal)"; return 0; }
    echo "  internal capture failed for $1; falling back to GNOME Print-key flow"
    ydotool key 210:1 210:0; sleep 1.2; ydotool key 28:1 28:0; sleep 1.5
    local newest
    newest=$(ls -t "$HOME/Pictures/Screenshots/"*.png 2>/dev/null | head -1)
    if [[ -n "$newest" ]]; then cp "$newest" "$CAPS/$1.png"; echo "  captured $1 (Print-key)"; return 0; fi
    echo "  CAPTURE FAILED: $1"; return 1
}

# 1) closed-state capture
capture 10-real-closed

# 2) real click on the panel button → popup opens
click_at "$PX" "$PY"; sleep 1.0
check "open after real click" True "$(ext_status_key open)"
capture 11-real-open

# 3) Escape closes (real key injection through the popup grab)
ydotool key 1:1 1:0
sleep 0.8
check "closed after Escape" False "$(ext_status_key open)"
capture 12-real-after-escape

# 4) outside click closes
click_at "$PX" "$PY"; sleep 0.9
check "reopened for outside-click test" True "$(ext_status_key open)"
click_at "$(python3 -c "print(int(960 * $SCALE))")" "$(python3 -c "print(int(540 * $SCALE))")"
sleep 0.8
check "closed after outside click" False "$(ext_status_key open)"
capture 13-real-after-outside-click

# 5) global keybinding (Super+Shift+p)
gsettings set org.gnome.shell.extensions.planify-quick-view toggle-quick-view "['<Super><Shift>p']"
sleep 0.3
ydotool key 125:1 42:1 25:1 25:0 42:0 125:0
sleep 1.0
check "open after keybinding" True "$(ext_status_key open)"
capture 14-real-open-keybinding
ydotool key 125:1 42:1 25:1 25:0 42:0 125:0
sleep 0.8
check "closed after keybinding again" False "$(ext_status_key open)"

# 6) inline quick-add: ToggleAdd reveals the entry, typed text + Enter
#    (real keys through the popup grab) must create a task due today
timeout 5 gdbus call --session --dest "$EXT_DBUS" --object-path "$EXT_DBUS_PATH" \
    --method "$EXT_DBUS.ToggleAdd" >/dev/null 2>&1
sleep 0.6
ydotool type "🧪 pqv auto-add test"
sleep 0.5
ydotool key 28:1 28:0
sleep 2.5
TODAY=$(date +%F)
if sqlite3 -readonly ~/.var/app/io.github.alainm23.planify/data/io.github.alainm23.planify/database.db \
    "SELECT 1 FROM Items WHERE content LIKE '%🧪 pqv auto-add test%' AND substr(json_extract(due,'\$.date'),1,10) = '$TODAY';" \
    2>/dev/null | grep -q 1; then
    echo "PASS: inline quick-add created task due today"
else
    echo "FAIL: inline quick-add task not found in database"
    FAILED=1
fi
capture 15-real-add

echo
if [[ $FAILED -eq 0 ]]; then echo "== real-session e2e PASSED =="; else echo "== real-session e2e had FAILURES =="; fi
echo "captures: $CAPS  |  tasks today: $TASKS"
exit $FAILED
