#!/usr/bin/env bash
# Headless VISUAL suite: records the nested clean-room shell with the GNOME
# screencast service while the popup opens and closes, then extracts frames.
# Produces real pixels for design review even though no display is attached.
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh

WORK=/tmp/pqv-visual
CAPS="$WORK/captures"
rm -rf "$WORK"; mkdir -p "$CAPS" "$WORK/config"
export XDG_CONFIG_HOME="$WORK/config"
export GNOME_SHELL_SESSION_MODE=user

./install.sh >/dev/null
echo "== launching headless shell for visual capture =="

timeout 220 dbus-run-session -- bash -s "$UUID" "$WORK" "$CAPS" <<'INSIDE'
set -uo pipefail
UUID="$1"; WORK="$2"; CAPS="$3"
LOG="$WORK/shell.log"
export GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/$UUID/schemas"

gnome-shell --wayland --headless --virtual-monitor 1400x900 >"$LOG" 2>&1 &
SHELL_PID=$!
trap 'kill -9 "$ANIM_PID" "$SHELL_PID" 2>/dev/null' EXIT

for i in $(seq 1 40); do
    WLDISPLAY=$(grep -o "Using Wayland display name '[^']*'" "$LOG" 2>/dev/null | cut -d"'" -f2 | head -1)
    [[ -n "$WLDISPLAY" ]] && break
    sleep 0.5
done
echo "wayland display: ${WLDISPLAY:-none}"
[[ -n "${WLDISPLAY:-}" ]] && WAYLAND_DISPLAY="$WLDISPLAY" gjs -m tests/animclient.mjs >"$WORK/animclient.log" 2>&1 &
ANIM_PID=$!

for i in $(seq 1 40); do timeout 5 gnome-extensions list >/dev/null 2>&1 && break; sleep 0.5; done
timeout 8 gnome-extensions enable "$UUID" >/dev/null
sleep 1.5
timeout 8 gsettings set org.gnome.shell.extensions.planify-quick-view debug-dbus true

EXT_DBUS=io.github.alainm23.planify.QuickView
EXT_DBUS_PATH=/io/github/alainm23/planify/QuickView
ext_call() { timeout 6 gdbus call --session --dest "$EXT_DBUS" --object-path "$EXT_DBUS_PATH" --method "$EXT_DBUS.$1" ${2:-}; }
wait_ext() { local n=0; while ! ext_call Status >/dev/null 2>&1; do n=$((n+1)); [[ $n -gt 30 ]] && return 1; sleep 0.5; done; }

wait_ext || { echo "FAIL: no debug dbus"; tail -30 "$LOG"; exit 1; }
echo "debug dbus up"

# Pump repaints so the stage paints without a real display.
ext_call Repaint true >/dev/null
sleep 1

CAST_DIR="$WORK/cast"
mkdir -p "$CAST_DIR"

record() { # record <name> <script...>
    local NAME="$1"; shift
    timeout 10 gdbus call --session --dest org.gnome.Shell.Screencast \
        --object-path /org/gnome/Shell/Screencast \
        --method org.gnome.Shell.Screencast.Screencast \
        " '$WORK/cast/$NAME.webm'" "{'framerate': <int32 25>, 'draw-cursor': <false>}"
    sleep 0.3
    "$@"
    sleep 0.5
    timeout 8 gdbus call --session --dest org.gnome.Shell.Screencast \
        --object-path /org/gnome/Shell/Screencast \
        --method org.gnome.Shell.Screencast.StopScreencast
    sleep 0.5
    ls -la "$CAST_DIR/" 2>/dev/null | grep -q "$NAME" && echo "RECORDED: $NAME" || echo "NOT RECORDED: $NAME"
}

echo "== phase A: animations enabled (animation behavior probe) =="
record anim-open ext_call Open
sleep 0.5
record anim-close ext_call Close
sleep 0.5
ext_call Status | python3 -c "
import sys,ast,json
s=json.loads(ast.literal_eval(sys.stdin.read().strip())[0])
print('after animated close: open =', s['open'], '| frameTime =', s.get('frameTime'), '| diagError =', s.get('diagError'))
"

echo "== phase B: reduced motion (deterministic visuals) =="
timeout 8 gsettings set org.gnome.desktop.interface enable-animations false
sleep 0.3
record closed-state true
record open-state ext_call Open
sleep 0.5
ext_call Status | python3 -c "
import sys,ast,json
s=json.loads(ast.literal_eval(sys.stdin.read().strip())[0])
print('reduced-motion open:', s['open'], 'rows:', s['rows'])
"
record close-state ext_call Close
sleep 0.3

kill -9 "$ANIM_PID" "$SHELL_PID" 2>/dev/null
echo "== extracting frames =="
exit 0
INSIDE

RC=$?
echo "inner rc=$RC"
ls -la "$WORK/cast/" 2>/dev/null
# Extract representative frames from each recording
for f in "$WORK/cast"/*.webm; do
    [[ -e "$f" ]] || continue
    base=$(basename "$f" .webm)
    ffmpeg -y -loglevel error -i "$f" -vf "select='eq(n\,0)+eq(n\,10)+eq(n\,25)'" -vsync vfr "$CAPS/$base-frame%d.png" 2>&1 | head -2
    # also grab the final frame
    ffmpeg -y -loglevel error -sseof -0.2 -i "$f" -update 1 -frames:v 1 "$CAPS/$base-last.png" 2>&1 | head -2
done
echo "== captures ready: =="
ls -la "$CAPS/" 2>/dev/null
