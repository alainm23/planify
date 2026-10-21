#!/bin/bash
# Build Planify on macOS. Used by run-macos.sh and the CI workflow.

set -euo pipefail

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
export PKG_CONFIG_PATH="/opt/homebrew/opt/libical/lib/pkgconfig:/opt/homebrew/opt/icu4c/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

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
meson compile -C build

# Compile gschemas locally (needed for in-tree runs)
echo "Compiling gschemas..."
glib-compile-schemas data

echo "Build complete."
