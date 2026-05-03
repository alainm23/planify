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

# Ensure pkg-config can find Homebrew libs (libical, icu4c)
export PKG_CONFIG_PATH="/opt/homebrew/opt/libical/lib/pkgconfig:/opt/homebrew/opt/icu4c/lib/pkgconfig:${PKG_CONFIG_PATH}"

# Configure with meson without optional dependencies
echo "Configuring project..."
meson setup build \
    -Dspelling=disabled \
    -Dportal=false \
    -Devolution=false \
    -Dgxml-0.20:docs=false \
    -Dc_args="-D__APPLE__" \
    -Dvala_args="--define=__APPLE__"

# Compile
echo "Compiling..."
if meson compile -C build; then
    # Compile gschemas locally
    echo "Compiling gschemas..."
    glib-compile-schemas data
    
    # Run with environment variables for schemas
    echo "Running Planify..."
    echo ""

    # libplanify is built into build/core, required at runtime
    export DYLD_LIBRARY_PATH="$(pwd)/build/core:${DYLD_LIBRARY_PATH}"

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
else
    echo "Compilation error"
    exit 1
fi
