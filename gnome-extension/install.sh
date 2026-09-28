#!/usr/bin/env bash
# Install / uninstall the extension into the user session.
#   ./install.sh              install (registers with a running shell, too)
#   ./install.sh --enable     install + enable (loaded at the next login if
#                             the running shell does not know it yet)
#   ./install.sh --uninstall  disable, uninstall, remove files
set -euo pipefail
cd "$(dirname "$0")"

UUID=$(grep -oP '(?<="uuid": ")[^"]+' src/metadata.json)
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/$UUID"

if [[ "${1:-}" == "--uninstall" ]]; then
    gnome-extensions disable "$UUID" >/dev/null 2>&1 || true
    sleep 0.5
    gnome-extensions uninstall "$UUID" >/dev/null 2>&1 || true
    rm -rf "$DEST"
    echo "Uninstalled $UUID"
    exit 0
fi

# Compile schemas first: the zip must carry gschemas.compiled so the
# extension's GSettings work immediately after a live install.
glib-compile-schemas src/schemas
mkdir -p dist
rm -f dist/planify-quick-view.zip
(cd src && zip -qr ../dist/planify-quick-view.zip \
    metadata.json extension.js prefs.js stylesheet.css stylesheet-dark.css \
    stylesheet-light.css schemas)

# gnome-extensions install registers the extension with a RUNNING shell
# (a plain file copy is only seen on the next session start).
if gnome-extensions install --force dist/planify-quick-view.zip 2>/dev/null; then
    echo "Installed via gnome-extensions (live)"
else
    # Fallback: manual copy for offline installs.
    rm -rf "$DEST"
    mkdir -p "$DEST"
    cp src/metadata.json src/extension.js src/prefs.js src/stylesheet.css \
       src/stylesheet-dark.css src/stylesheet-light.css "$DEST/"
    rm -rf "$DEST/schemas"
    cp -r src/schemas "$DEST/schemas"
    glib-compile-schemas "$DEST/schemas" 2>/dev/null || true
    echo "Installed by file copy: $DEST"
fi

if [[ "${1:-}" == "--enable" ]]; then
    # A live shell may not know a freshly-installed extension yet (it scans
    # extension directories at session start, and only EGO-website installs
    # load live). Writing enabled-extensions directly guarantees the panel
    # button appears at the next login either way.
    gnome-extensions enable "$UUID" 2>/dev/null || true
    ENABLED=$(gsettings get org.gnome.shell enabled-extensions)
    if [[ "$ENABLED" != *"$UUID"* ]]; then
        NEWLIST=$(printf '%s' "$ENABLED" | python3 -c "
import sys, ast
uuid = '$UUID'
try:
    lst = ast.literal_eval(sys.stdin.read().strip())
except Exception:
    lst = []
lst = [u for u in lst if u != uuid] + [uuid]
print(str(lst))")
        gsettings set org.gnome.shell enabled-extensions "$NEWLIST"
    fi
    echo "Enabled $UUID (the running shell loads it at the next login)"
fi
