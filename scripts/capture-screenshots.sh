#!/bin/bash
set -e

APP_NAME="StaBar"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${PROJECT_ROOT}/screenshots"

echo "🎯 StaBar Screenshot Capture Tool"
echo "================================"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if StaBar is running
if ! pgrep -x "$APP_NAME" > /dev/null; then
    echo "🚀 Launching StaBar..."
    open "${PROJECT_ROOT}/build/Release/${APP_NAME}.app"
    sleep 2
fi

echo "📸 Step 1: Capturing menu bar..."
echo "   The menu bar screenshot will show StaBar's multi-column layout"

# Capture just the menu bar area (top 40 pixels of main screen)
# For Retina displays, we need to double the pixel dimensions
screencapture -x "$OUTPUT_DIR/01_menubar_raw.png"

echo "   ✓ Raw screenshot saved"

echo ""
echo "📸 Step 2: Opening settings popover..."
echo "   Click the StaBar menu bar icon to open settings"
echo "   The script will capture it in 3 seconds..."

# Use AppleScript to click the menu bar icon (approximate position)
osascript <> EOL
    tell application "System Events"
        tell process "StaBar"
            click menu bar item 1 of menu bar 1
        end tell
    end tell
EOL

sleep 0.5
screencapture -x "$OUTPUT_DIR/02_settings_raw.png"

echo "   ✓ Settings popover screenshot saved"
echo ""

echo "🎨 Step 3: Processing images (adding rounded corners + shadows)..."

# Swift script for image processing
cat > /tmp/process_for_docs.swift << 'SWIFTEOF'
import Cocoa
import Foundation

func processScreenshot(inputPath: String, outputPath: String, cornerRadius: CGFloat = 16) {
    guard let inputImage = NSImage(contentsOfFile: inputPath) else {
        print("❌ Failed to load: \(inputPath)")
        return
    }
    
    let inputSize = inputImage.size
    let scale = inputImage.representations.first?.pixelsWide ?? Int(inputSize.width) / Int(inputSize.width)
    
    // For menu bar: crop to just show the menu bar area
    let isMenuBar = inputPath.contains("menubar")
    
    var cropRect: CGRect
    if isMenuBar {
        // Menu bar is at the very top, about 24-28 points high
        // We'll crop a section from the center showing the menu bar
        let menuBarHeight: CGFloat = 32
        let screenWidth = inputSize.width
        cropRect = CGRect(x: screenWidth * 0.2, y: inputSize.height - menuBarHeight, 
                         width: screenWidth * 0.6, height: menuBarHeight)
    } else {
        // For popover, crop to the center area where the popover appears
        let popoverWidth: CGFloat = 300
        let popoverHeight: CGFloat = 400
        cropRect = CGRect(
            x: (inputSize.width - popoverWidth) / 2,
            y: (inputSize.height - popoverHeight) / 2,
            width: popoverWidth,
            height: popoverHeight
        )
    }
    
    // Create cropped image
    let croppedImage = NSImage(size: cropRect.size)
    croppedImage.lockFocus()
    inputImage.draw(at: NSPoint(x: -cropRect.origin.x, y: -cropRect.origin.y), 
                   from: CGRect(origin: .zero, size: inputSize), 
                   operation: .copy, 
                   fraction: 1.0)
    croppedImage.unlockFocus()
    
    // Now add rounded corners and shadow
    let padding: CGFloat = 30
    let outputSize = CGSize(
        width: cropRect.size.width + padding * 2,
        height: cropRect.size.height + padding * 2
    )
    
    let finalImage = NSImage(size: outputSize)
    finalImage.lockFocus()
    
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    
    // Clear to transparent
    context.clear(CGRect(origin: .zero, size: outputSize))
    
    // Create rounded rect
    let drawRect = CGRect(x: padding, y: padding, width: cropRect.width, height: cropRect.height)
    let path = NSBezierPath(roundedRect: drawRect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Draw shadow
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -8), blur: 20, 
                     color: NSColor.black.withAlphaComponent(0.25).cgColor)
    NSColor.white.setFill()
    path.fill()
    context.restoreGState()
    
    // Draw image inside rounded rect
    path.addClip()
    croppedImage.draw(in: drawRect)
    
    finalImage.unlockFocus()
    
    // Save
    guard let tiffData = finalImage.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("❌ Failed to encode: \(outputPath)")
        return
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("   ✓ Processed: \(outputPath)")
    } catch {
        print("❌ Failed to save: \(error)")
    }
}

// Process both images
let outputDir = CommandLine.arguments[1]
processScreenshot(
    inputPath: "\(outputDir)/01_menubar_raw.png",
    outputPath: "\(outputDir)/screenshot_menubar.png",
    cornerRadius: 12
)
processScreenshot(
    inputPath: "\(outputDir)/02_settings_raw.png",
    outputPath: "\(outputDir)/screenshot_settings.png",
    cornerRadius: 20
)
SWIFTEOF

swift /tmp/process_for_docs.swift "$OUTPUT_DIR"

# Clean up raw screenshots
rm "$OUTPUT_DIR/01_menubar_raw.png" "$OUTPUT_DIR/02_settings_raw.png"

echo ""
echo "✅ Screenshots saved to: $OUTPUT_DIR"
echo ""
echo "📁 Generated files:"
ls -lh "$OUTPUT_DIR"/*.png
echo ""
echo "💡 Tip: To add these to your README, use:"
echo "   ![Menu Bar](screenshots/screenshot_menubar.png)"
echo "   ![Settings](screenshots/screenshot_settings.png)"
