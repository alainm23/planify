#!/bin/bash
# Package Planify into a minimal macOS .app bundle and DMG (experimental).
# Assumes you've already built with ./run-macos.sh and have ./build artifacts.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
DESTDIR="$BUILD/dist"
APPDIR="$BUILD/Planify.app"
DMG="$BUILD/Planify.dmg"
BIN_NAME="io.github.alainm23.planify"

if [ ! -x "$BUILD/src/$BIN_NAME" ]; then
  echo "Planify binary not found in $BUILD/src. Run ./run-macos.sh first." >&2
  exit 1
fi

echo "Staging install to $DESTDIR..."
meson install -C "$BUILD" --destdir "$DESTDIR"

echo "Building app bundle at $APPDIR..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/Contents/MacOS" "$APPDIR/Contents/Resources"

# Main binary and wrapper
cp "$DESTDIR/opt/homebrew/bin/$BIN_NAME" "$APPDIR/Contents/MacOS/planify-bin"
cat > "$APPDIR/Contents/MacOS/Planify" <<'EOF'
#!/bin/bash
APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RES="$APP_ROOT/Resources"
export GSETTINGS_SCHEMA_DIR="$RES/glib-2.0/schemas"
export XDG_DATA_DIRS="$RES:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export FONTCONFIG_PATH=/opt/homebrew/etc/fonts
export FONTCONFIG_FILE=/opt/homebrew/etc/fonts/fonts.conf
export PANGO_EMOJI_FONT="Apple Color Emoji"
exec "$APP_ROOT/MacOS/planify-bin" "$@"
EOF
chmod +x "$APPDIR/Contents/MacOS/Planify"

# Resources (schemas/icons/locale/etc.)
cp -R "$DESTDIR/opt/homebrew/share/." "$APPDIR/Contents/Resources/"
glib-compile-schemas "$APPDIR/Contents/Resources/glib-2.0/schemas"

# Bundle Planify libs (not fully self-contained; still uses Homebrew GTK stack)
cp "$DESTDIR/opt/homebrew/lib/libplanify.0.dylib" "$APPDIR/Contents/MacOS/"
if [ -f "/opt/homebrew/lib/libgxml-0.20.2.0.2.dylib" ]; then
  cp "/opt/homebrew/lib/libgxml-0.20.2.0.2.dylib" "$APPDIR/Contents/MacOS/"
  install_name_tool -change /opt/homebrew/lib/libgxml-0.20.2.0.2.dylib @executable_path/libgxml-0.20.2.0.2.dylib "$APPDIR/Contents/MacOS/libplanify.0.dylib"
fi
install_name_tool -change /opt/homebrew/lib/libplanify.0.dylib @executable_path/libplanify.0.dylib "$APPDIR/Contents/MacOS/planify-bin"
install_name_tool -id @executable_path/libplanify.0.dylib "$APPDIR/Contents/MacOS/libplanify.0.dylib"

# Copy and convert app icon to .icns
ICON_PNG="$ROOT/data/icons/io.github.alainm23.planify.png"
if [ -f "$ICON_PNG" ]; then
  echo "Converting PNG icon to .icns..."
  mkdir -p /tmp/planify.iconset
  sips -z 16 16     "$ICON_PNG" --out /tmp/planify.iconset/icon_16x16.png 2>/dev/null
  sips -z 32 32     "$ICON_PNG" --out /tmp/planify.iconset/icon_16x16@2x.png 2>/dev/null
  sips -z 32 32     "$ICON_PNG" --out /tmp/planify.iconset/icon_32x32.png 2>/dev/null
  sips -z 64 64     "$ICON_PNG" --out /tmp/planify.iconset/icon_32x32@2x.png 2>/dev/null
  sips -z 128 128   "$ICON_PNG" --out /tmp/planify.iconset/icon_128x128.png 2>/dev/null
  sips -z 256 256   "$ICON_PNG" --out /tmp/planify.iconset/icon_128x128@2x.png 2>/dev/null
  sips -z 256 256   "$ICON_PNG" --out /tmp/planify.iconset/icon_256x256.png 2>/dev/null
  sips -z 512 512   "$ICON_PNG" --out /tmp/planify.iconset/icon_256x256@2x.png 2>/dev/null
  sips -z 512 512   "$ICON_PNG" --out /tmp/planify.iconset/icon_512x512.png 2>/dev/null
  iconutil -c icns /tmp/planify.iconset -o "$APPDIR/Contents/Resources/planify.icns" 2>/dev/null
  rm -rf /tmp/planify.iconset
  echo "App icon created: planify.icns"
else
  echo "Warning: Icon not found at $ICON_PNG"
fi

# Info.plist with version from the build config
VERSION="$(grep -E 'public const string VERSION' "$BUILD/config.vala" | sed 's/.*\"\\(.*\\)\";/\\1/')" || VERSION="0.0.0"
cat > "$APPDIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Planify</string>
  <key>CFBundleIdentifier</key><string>io.github.alainm23.planify</string>
  <key>CFBundleName</key><string>Planify</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleIconFile</key><string>planify.icns</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

echo "Creating DMG at $DMG..."
rm -f "$DMG"
hdiutil create -volname "Planify" -srcfolder "$APPDIR" -ov -format UDZO "$DMG"
echo "Done: $DMG"
