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

log_info "Creating DMG staging directory..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

log_info "Copying $APP_NAME.app to staging directory..."
cp -r "$APP_PATH" "$STAGING_DIR/"

log_info "Creating Applications symlink..."
ln -s /Applications "$STAGING_DIR/Applications"

log_info "Creating DMG with hdiutil..."
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

if [ ! -f "$DMG_NAME" ]; then
    log_error "DMG creation failed: $DMG_NAME not found"
    exit 1
fi

log_info "Cleaning up staging directory..."
rm -rf "$STAGING_DIR"

# Get DMG file size
DMG_SIZE=$(ls -lh "$DMG_NAME" | awk '{print $5}')
log_info "DMG created successfully: $DMG_NAME ($DMG_SIZE)"
log_info "DMG is ready for distribution!"
