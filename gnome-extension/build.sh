#!/usr/bin/env bash
# Package the extension the way extensions.gnome.org expects:
# metadata.json + extension.js + stylesheets + schemas/ at the zip root.
set -euo pipefail
cd "$(dirname "$0")"

UUID=$(grep -oP '(?<="uuid": ")[^"]+' src/metadata.json)
DIST=dist
mkdir -p "$DIST"

# Compile the GSettings schema so local installs work out of the box.
glib-compile-schemas src/schemas

rm -f "$DIST/planify-quick-view.zip"
(cd src && zip -qr "../$DIST/planify-quick-view.zip" \
    metadata.json extension.js prefs.js stylesheet.css stylesheet-dark.css stylesheet-light.css schemas)

echo "Built $DIST/planify-quick-view.zip for $UUID"
