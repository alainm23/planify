#!/bin/bash

# Script to build and run Planify on macOS without optional dependencies

cd "$(dirname "$0")"

# Build
chmod +x scripts/build-macos.sh
./scripts/build-macos.sh

# Run with environment variables for schemas
echo "Running Planify..."
echo ""

# libplanify is built into build/core, required at runtime
export DYLD_LIBRARY_PATH="$(pwd)/build/core:${DYLD_LIBRARY_PATH:-}"

# Configure Pango and Cairo for macOS
export GIO_MODULE_DIR=/opt/homebrew/lib/gio/modules
export FONTCONFIG_PATH=/opt/homebrew/etc/fonts
export FONTCONFIG_FILE=/opt/homebrew/etc/fonts/fonts.conf
export XDG_DATA_DIRS=/opt/homebrew/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}

# Use macOS system fonts as fallback
export PANGO_EMOJI_FONT="Apple Color Emoji"

# Force app to appear in Dock on macOS (GTK4 uses 'macos', not 'quartz')
export GDK_BACKEND=macos

GSETTINGS_SCHEMA_DIR=data ./build/src/io.github.alainm23.planify
