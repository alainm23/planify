#!/bin/bash

# Script to build and run Planify on macOS without optional dependencies

# Check critical dependencies
echo "Checking dependencies..."
for dep in pango cairo fontconfig; do
    if ! brew list $dep &>/dev/null; then
        echo "Installing $dep..."
        brew install $dep
    fi
done

# Clean previous build if exists
if [ -d "build" ]; then
    echo "Cleaning previous build..."
    rm -rf build
fi

# Configure with meson without optional dependencies
echo "Configuring project..."
meson setup build \
    -Dwebkit=false \
    -Dspelling=disabled \
    -Dportal=false \
    -Devolution=false

# Compile
echo "Compiling..."
if meson compile -C build; then
    # Compile gschemas locally
    echo "Compiling gschemas..."
    glib-compile-schemas data
    
    # Run with environment variables for schemas
    echo "Running Planify..."
    echo ""
    
    # Configure Pango and Cairo for macOS
    export FONTCONFIG_PATH=/opt/homebrew/etc/fonts
    export FONTCONFIG_FILE=/opt/homebrew/etc/fonts/fonts.conf
    export XDG_DATA_DIRS=/opt/homebrew/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
    
    # Use macOS system fonts as fallback
    export PANGO_EMOJI_FONT="Apple Color Emoji"
    
    # Force app to appear in Dock on macOS
    export GDK_BACKEND=quartz
    
    GSETTINGS_SCHEMA_DIR=data ./build/src/io.github.alainm23.planify
else
    echo "Compilation error"
    exit 1
fi
