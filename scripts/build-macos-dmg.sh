#!/bin/bash
# Build a self-contained Planify.app + DMG for macOS.
# Requirements: dylibbundler, create-dmg, rsvg-convert (librsvg)
#   brew install dylibbundler create-dmg librsvg
#
# Usage: ./scripts/build-macos-dmg.sh
# Run ./run-macos.sh first to compile the project.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
APPDIR="$BUILD/Planify.app"
DMG="$BUILD/Planify.dmg"
BIN_NAME="io.github.alainm23.planify"
BREW="/opt/homebrew"

# ── 0. Checks ────────────────────────────────────────────────────────────────
if [ ! -x "$BUILD/src/$BIN_NAME" ]; then
  echo "ERROR: Binary not found. Run ./run-macos.sh first." >&2
  exit 1
fi

for tool in dylibbundler create-dmg rsvg-convert; do
  if ! command -v "$tool" &>/dev/null; then
    echo "ERROR: '$tool' not found. Run: brew install dylibbundler create-dmg librsvg" >&2
    exit 1
  fi
done

# ── 1. App bundle skeleton ────────────────────────────────────────────────────
echo "→ Creating app bundle..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/Contents/MacOS"
mkdir -p "$APPDIR/Contents/Resources"
mkdir -p "$APPDIR/Contents/libs"

# Copy binaries
cp "$BUILD/src/$BIN_NAME"        "$APPDIR/Contents/MacOS/planify-bin"
cp "$BUILD/core/libplanify.0.dylib" "$APPDIR/Contents/libs/"

# ── 2. Launcher wrapper ───────────────────────────────────────────────────────
cat > "$APPDIR/Contents/MacOS/Planify" <<'LAUNCHER'
#!/bin/bash
APP="$(cd "$(dirname "$0")/.." && pwd)"
RES="$APP/Resources"

export DYLD_LIBRARY_PATH="$APP/libs:${DYLD_LIBRARY_PATH:-}"
export GSETTINGS_SCHEMA_DIR="$RES/glib-2.0/schemas"
export XDG_DATA_DIRS="$RES:${BREW:-/opt/homebrew}/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export GDK_BACKEND=macos
export GIO_MODULE_DIR="/opt/homebrew/lib/gio/modules"
export FONTCONFIG_PATH="$RES/fonts"
export FONTCONFIG_FILE="$RES/fonts/fonts.conf"
export PANGO_EMOJI_FONT="Apple Color Emoji"
export GTK_FONT_NAME="Adwaita Sans 11"

# Handle OAuth callback: if called with a planify:// URI write it to a handoff
# file and exit. The running instance polls that file every 500ms.
if [ $# -gt 0 ] && echo "$1" | grep -q '^planify://'; then
    echo "$1" > "${TMPDIR}planify-oauth-handoff"
    exit 0
fi

exec "$APP/MacOS/planify-bin" "$@"
LAUNCHER
chmod +x "$APPDIR/Contents/MacOS/Planify"

# ── 3. Bundle all dylib dependencies ─────────────────────────────────────────
echo "→ Bundling dylibs (this may take a moment)..."
dylibbundler -od -b \
  -x "$APPDIR/Contents/MacOS/planify-bin" \
  -x "$APPDIR/Contents/libs/libplanify.0.dylib" \
  -d "$APPDIR/Contents/libs/" \
  -p @executable_path/../libs/ \
  -s "$BUILD/core" \
  -s "$BREW/lib"

# Fix libplanify rpath in the main binary
install_name_tool \
  -change "@rpath/libplanify.0.dylib" "@executable_path/../libs/libplanify.0.dylib" \
  "$APPDIR/Contents/MacOS/planify-bin"

# dylibbundler adds LC_RPATH once per dylib processed → duplicates crash dyld on macOS 26+
# Remove all copies and add exactly one
echo "→ Deduplicating LC_RPATH entries..."
for bin in "$APPDIR/Contents/MacOS/planify-bin" "$APPDIR/Contents/libs/libplanify.0.dylib"; do
  [ -f "$bin" ] || continue
  count=$(otool -l "$bin" | grep -c '@executable_path/../libs/' || true)
  for _ in $(seq 1 "$count"); do
    install_name_tool -delete_rpath '@executable_path/../libs/' "$bin" 2>/dev/null || break
  done
  install_name_tool -add_rpath '@executable_path/../libs/' "$bin"
done

# ── 4. GSettings schemas ─────────────────────────────────────────────────────
# Must happen BEFORE codesign --deep so Resources/ is included in the signature
echo "→ Copying schemas..."
SCHEMA_DIR="$APPDIR/Contents/Resources/glib-2.0/schemas"
mkdir -p "$SCHEMA_DIR"

# Copy ONLY the Planify schema to a clean dir and compile it alone.
# Mixing Homebrew GNOME schemas causes glib-compile-schemas to fail silently
# and produce a compiled file that doesn't include the Planify schema.
cp "$ROOT/data/io.github.alainm23.planify.gschema.xml" "$SCHEMA_DIR/"
glib-compile-schemas "$SCHEMA_DIR/"

# Verify the key exists in the compiled output
if ! glib-compile-schemas --dry-run "$SCHEMA_DIR/" 2>&1 | grep -q 'label-picker-hide-unused' 2>/dev/null; then
  # dry-run doesn't show keys, so verify via the source file
  grep -q 'label-picker-hide-unused' "$SCHEMA_DIR/io.github.alainm23.planify.gschema.xml" || {
    echo "ERROR: label-picker-hide-unused key missing from schema" >&2; exit 1
  }
fi
echo "  Schemas compiled OK"

# Re-sign everything after all modifications (required on macOS 13+)
echo "→ Re-signing binaries..."
find "$APPDIR/Contents/libs" -name "*.dylib" | while read -r lib; do
  codesign --force --sign - "$lib"
done
codesign --force --sign - "$APPDIR/Contents/MacOS/planify-bin"
codesign --force --deep --sign - "$APPDIR"

# ── 5. Fonts ───────────────────────────────────────────────────────────
echo "→ Bundling fonts..."
FONT_DIR="$APPDIR/Contents/Resources/fonts"
mkdir -p "$FONT_DIR"

# Copy Adwaita fonts (from brew cask font-adwaita)
for f in AdwaitaSans-Regular.ttf AdwaitaSans-Italic.ttf AdwaitaMono-Regular.ttf AdwaitaMono-Italic.ttf AdwaitaMono-Bold.ttf AdwaitaMono-BoldItalic.ttf; do
  [ -f "$HOME/Library/Fonts/$f" ] && cp "$HOME/Library/Fonts/$f" "$FONT_DIR/"
done

# Generate a self-contained fonts.conf pointing to bundled fonts + macOS system fonts
cat > "$FONT_DIR/fonts.conf" <<'FONTSCONF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Bundled Adwaita fonts -->
  <dir prefix="default">.</dir>
  <!-- macOS system fonts as fallback -->
  <dir>/System/Library/Fonts</dir>
  <dir>/Library/Fonts</dir>
  <dir>~/Library/Fonts</dir>
  <cachedir prefix="xdg">fontconfig</cachedir>
</fontconfig>
FONTSCONF

# ── 6. Icons ──────────────────────────────────────────────────────────────────
echo "→ Copying icons..."
mkdir -p "$APPDIR/Contents/Resources/share/icons"
cp -R "$BREW/share/icons/Adwaita"  "$APPDIR/Contents/Resources/share/icons/" 2>/dev/null || echo "  Warning: Adwaita icons not found"
cp -R "$BREW/share/icons/hicolor"  "$APPDIR/Contents/Resources/share/icons/" 2>/dev/null || true
# App icons into hicolor
cp -R "$ROOT/data/icons/hicolor" "$APPDIR/Contents/Resources/share/icons/"

# ── 6. Locale ─────────────────────────────────────────────────────────────────
echo "→ Copying locale..."
if [ -d "$BUILD/po" ]; then
  mkdir -p "$APPDIR/Contents/Resources/share/locale"
  cp -R "$BUILD/po/." "$APPDIR/Contents/Resources/share/locale/" 2>/dev/null || true
fi

# ── 7. App icon (.icns) ───────────────────────────────────────────────────────
echo "→ Generating app icon..."
SVG="$ROOT/data/icons/hicolor/scalable/apps/io.github.alainm23.planify.svg"
ICONSET="$BUILD/planify.iconset"
rm -rf "$ICONSET" && mkdir "$ICONSET"

for size in 16 32 64 128 256 512; do
  rsvg-convert -w $size -h $size "$SVG" -o "$ICONSET/icon_${size}x${size}.png"
  rsvg-convert -w $((size*2)) -h $((size*2)) "$SVG" -o "$ICONSET/icon_${size}x${size}@2x.png"
done

iconutil -c icns "$ICONSET" -o "$APPDIR/Contents/Resources/Planify.icns"
rm -rf "$ICONSET"

# ── 8. Info.plist ─────────────────────────────────────────────────────────────
VERSION="$(grep -E 'VERSION\s*=' "$BUILD/config.vala" 2>/dev/null | head -1 | sed 's/.*"\(.*\)".*/\1/')" || VERSION="4.0.0"

cat > "$APPDIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Planify</string>
  <key>CFBundleIdentifier</key><string>io.github.alainm23.planify</string>
  <key>CFBundleName</key><string>Planify</string>
  <key>CFBundleDisplayName</key><string>Planify</string>
  <key>CFBundleIconFile</key><string>Planify</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key><string>io.github.alainm23.planify</string>
      <key>CFBundleURLSchemes</key>
      <array><string>planify</string></array>
    </dict>
  </array>
</dict></plist>
PLIST

# ── 9. DMG ────────────────────────────────────────────────────────────────────
echo "→ Creating DMG..."
rm -f "$DMG"
create-dmg \
  --volname "Planify" \
  --volicon "$APPDIR/Contents/Resources/Planify.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Planify.app" 150 185 \
  --hide-extension "Planify.app" \
  --app-drop-link 450 185 \
  "$DMG" \
  "$APPDIR"

echo ""
echo "✅ Done: $DMG"
echo "   Drag Planify.app to /Applications to install."
