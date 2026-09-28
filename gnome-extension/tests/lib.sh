#!/usr/bin/env bash
# Shared helpers for the e2e test scripts.

UUID=$(grep -oP '(?<="uuid": ")[^"]+' src/metadata.json)
EXT_DBUS=io.github.alainm23.planify.QuickView
EXT_DBUS_PATH=/io/github/alainm23/planify/QuickView

caps_dir() {  # caps_dir <name>
    mkdir -p "/tmp/pqv-captures/$1"
    echo "/tmp/pqv-captures/$1"
}

# gdbus helpers against the extension's debug interface (requires debug-dbus).
# Always bounded — an unanswered method must not hang the whole test run.
ext_call() {  # ext_call <method> [args-xml]
    timeout 5 gdbus call --session --dest "$EXT_DBUS" --object-path "$EXT_DBUS_PATH" \
        --method "$EXT_DBUS.$1" ${2:-}
}

# ext_status <jq-like key> — reads Status() JSON and extracts a key with python3.
ext_status_key() {
    ext_call Status | python3 -c "
import sys, ast
s = ast.literal_eval(sys.stdin.read().strip())[0]
import json
print(json.loads(s).get('$1'))
"
}

ext_status() {
    ext_call Status | python3 -c "
import sys, ast, json
s = ast.literal_eval(sys.stdin.read().strip())[0]
print(json.dumps(json.loads(s), indent=2))
"
}

ext_capture() {  # ext_capture <path>
    ext_call Capture " '$1'" | grep -q true
}

wait_ext() {  # wait_ext [timeout-seconds]
    local n=0 max="${1:-20}"
    while ! ext_call Status >/dev/null 2>&1; do
        n=$((n + 1))
        [[ $n -gt $((max * 2)) ]] && return 1
        sleep 0.5
    done
}

assert_eq() {  # assert_eq <desc> <expected> <actual>
    if [[ "$2" == "$3" ]]; then
        echo "PASS: $1 ($2)"
    else
        echo "FAIL: $1 — expected '$2', got '$3'"
        return 1
    fi
}

shell_errors() {  # shell_errors <shell-log-file>
    grep -nE "JS ERROR|Extension.*[Ee]rror|planify-quick-view.*(Error|WARN)" "$1" | grep -v "Bus Name" || true
}
