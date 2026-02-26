#!/bin/bash
set -e

# Configuration
APP_NAME="StaBar"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="./build"
RELEASE_DIR="${BUILD_DIR}/Release"
APP_PATH="${RELEASE_DIR}/${APP_NAME}.app"
STAGING_DIR="${BUILD_DIR}/dmg-staging"
ICONSET_DIR="${BUILD_DIR}/AppIcon.iconset"
ICNS_PATH="${BUILD_DIR}/AppIcon.icns"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "StaBar.xcodeproj/project.pbxproj" ]; then
    log_error "StaBar.xcodeproj not found. Please run this script from the project root."
    exit 1
fi

log_info "Building Release configuration..."
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -scheme StaBar -configuration Release SYMROOT=./build build

if [ ! -d "$APP_PATH" ]; then
    log_error "Build failed: $APP_PATH not found"
    exit 1
fi

log_info "Generating .icns file from AppIcon.appiconset..."
rm -rf "$ICONSET_DIR"
cp -r "StaBar/Assets.xcassets/AppIcon.appiconset" "$ICONSET_DIR"
rm -f "$ICONSET_DIR/Contents.json"
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"
rm -rf "$ICONSET_DIR"

log_info "Creating DMG staging directory..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

log_info "Copying $APP_NAME.app to staging directory..."
cp -r "$APP_PATH" "$STAGING_DIR/"

log_info "Creating Applications symlink..."
ln -s /Applications "$STAGING_DIR/Applications"

log_info "Setting DMG volume icon..."
cp "$ICNS_PATH" "$STAGING_DIR/.VolumeIcon.icns"
SetFile -c icnC "$STAGING_DIR/.VolumeIcon.icns"
SetFile -a C "$STAGING_DIR"

log_info "Creating DMG with hdiutil..."
rm -f "$DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

if [ ! -f "$DMG_NAME" ]; then
    log_error "DMG creation failed: $DMG_NAME not found"
    exit 1
fi

log_info "Setting icon for the DMG file itself..."
cat << 'EOF' > "${BUILD_DIR}/set_icon.swift"
import Cocoa
let args = CommandLine.arguments
if args.count != 3 { exit(1) }
guard let image = NSImage(contentsOfFile: args[1]) else { exit(1) }
let success = NSWorkspace.shared.setIcon(image, forFile: args[2], options: [])
if !success { exit(1) }
EOF
swift "${BUILD_DIR}/set_icon.swift" "$ICNS_PATH" "$DMG_NAME"

log_info "Cleaning up staging directory..."
rm -rf "$STAGING_DIR"
rm -f "${BUILD_DIR}/set_icon.swift"

# Get DMG file size
DMG_SIZE=$(ls -lh "$DMG_NAME" | awk '{print $5}')
log_info "DMG created successfully: $DMG_NAME ($DMG_SIZE)"
log_info "DMG is ready for distribution!"
