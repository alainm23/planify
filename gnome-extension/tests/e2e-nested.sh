#!/usr/bin/env bash
# Clean-room functional e2e: run the extension inside an isolated headless
# GNOME Shell (own D-Bus session, own dconf) and verify the complete state
# machine: install -> enable -> DB read -> open -> close -> disable teardown.
#
# Headless mutter on real GPUs renders no frames (no page flips), so visual
# assertions live in tests/e2e-real.sh (run inside a graphical session).
# Animations are disabled here so open/close take the deterministic
# reduced-motion path and the state machine is fully verifiable.
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh

WORK=/tmp/pqv-nested
rm -rf "$WORK"
mkdir -p "$WORK/config"
export XDG_CONFIG_HOME="$WORK/config"
export GNOME_SHELL_SESSION_MODE=user

./install.sh >/dev/null
echo "== extension installed; launching headless shell =="

timeout 160 dbus-run-session -- bash -s "$UUID" "$WORK" <<'INSIDE'
set -uo pipefail
UUID="$1"; WORK="$2"
LOG="$WORK/shell.log"
export GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/$UUID/schemas"

gnome-shell --wayland --headless --virtual-monitor 1400x900 >"$LOG" 2>&1 &
SHELL_PID=$!
trap 'kill -9 "$SHELL_PID" 2>/dev/null' EXIT

for i in $(seq 1 40); do timeout 5 gnome-extensions list >/dev/null 2>&1 && break; sleep 0.5; done
if ! timeout 5 gnome-extensions info "$UUID" >/dev/null 2>&1; then
    echo "FAIL: extension not visible to shell"; tail -40 "$LOG"; exit 1
fi

timeout 8 gnome-extensions enable "$UUID" >/dev/null
sleep 1.5
timeout 8 gsettings set org.gnome.shell.extensions.planify-quick-view debug-dbus true
# Deterministic state machine: no animation frames exist headless.
timeout 8 gsettings set org.gnome.desktop.interface enable-animations false

EXT_DBUS=io.github.alainm23.planify.QuickView
EXT_DBUS_PATH=/io/github/alainm23/planify/QuickView
ext_call() { timeout 6 gdbus call --session --dest "$EXT_DBUS" --object-path "$EXT_DBUS_PATH" --method "$EXT_DBUS.$1" ${2:-}; }
wait_ext() { local n=0; while ! ext_call Status >/dev/null 2>&1; do n=$((n+1)); [[ $n -gt 30 ]] && return 1; sleep 0.5; done; }
status_json() { ext_call Status | python3 -c "
import sys, ast, json
print(json.dumps(json.loads(ast.literal_eval(sys.stdin.read().strip())[0])))"; }
status_key() { status_json | python3 -c "import sys,json;print(json.load(sys.stdin).get('$1'))"; }

FAILED=0
check() {
    if [[ "$2" == "$3" ]]; then echo "PASS: $1 ($2)"; else echo "FAIL: $1 — expected '$2' got '$3'"; FAILED=1; fi
}

wait_ext || { echo "FAIL: debug D-Bus never appeared"; tail -40 "$LOG"; exit 1; }
echo "== debug D-Bus up =="

check "database found (real user data)" True "$(status_key dbFound)"
TASKS=$(status_key tasks)
echo "   today+overdue tasks visible to the shell: $TASKS"

check "closed initially" False "$(status_key open)"

# --- open ---
ext_call Open >/dev/null; sleep 0.5
check "open after Open()" True "$(status_key open)"
if [[ "$TASKS" != "0" ]]; then
    check "task rows rendered" True "$([[ $(status_key rows) -gt 0 ]] && echo True || echo False)"
else
    echo "INFO: no due tasks today; empty state shown"
fi
# idempotent open
ext_call Open >/dev/null; sleep 0.3
check "double-open is a no-op" True "$(status_key open)"

# --- close ---
ext_call Close >/dev/null; sleep 0.5
check "closed after Close()" False "$(status_key open)"
# idempotent close
ext_call Close >/dev/null; sleep 0.3
check "double-close is a no-op" False "$(status_key open)"
# toggle path
ext_call Toggle >/dev/null; sleep 0.3
check "Toggle opens" True "$(status_key open)"
ext_call Toggle >/dev/null; sleep 0.3
check "Toggle closes" False "$(status_key open)"

# --- data snapshot sanity ---
status_json | python3 -c "
import sys, json
s = json.load(sys.stdin)
assert isinstance(s['tasks'], int) and s['tasks'] >= 0, s
assert isinstance(s['doneToday'], int) and s['doneToday'] >= 0, s
assert s['dbPath'].endswith('database.db'), s
print('PASS: status snapshot well-formed (dbPath=' + s['dbPath'] + ')')
" || FAILED=1

# --- clean teardown ---
timeout 8 gnome-extensions disable "$UUID" >/dev/null 2>&1
sleep 1
if ext_call Status >/dev/null 2>&1; then
    echo "FAIL: debug D-Bus still alive after disable"; FAILED=1
else
    echo "PASS: debug D-Bus gone after disable (clean teardown)"
fi

echo "== extension JS errors in shell log =="
OURERR=$(grep -E "JS ERROR" -A 6 "$LOG" | grep -cF "planify-quick-view@" || true)
check "no extension JS errors" 0 "$OURERR"
grep -E "JS ERROR" "$LOG" | head -3

kill -9 "$SHELL_PID" 2>/dev/null
echo "SKIPPED (needs a rendering session): visuals, animations, real input — run tests/e2e-real.sh after login"
exit $FAILED
INSIDE

RC=$?
if [[ $RC -eq 0 ]]; then echo "== nested clean-room functional e2e PASSED =="; else echo "== nested clean-room functional e2e FAILED (rc=$RC) =="; fi
exit $RC
