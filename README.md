# StaBar

**[English](README.md) | [中文](README_zh.md)**

<center>
A lightweight native macOS menu bar system monitor built with Swift and SwiftUI.

![StaBar Icon](StaBar/Assets.xcassets/AppIcon.appiconset/icon_128x128.png)
![screen shot](images/figure.png)

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)
</center>

## Features

- **Real-time monitoring** — CPU, GPU, RAM, Disk, and Network metrics at a glance
- **Column layout display** — Each metric displayed in its own column with label on top and value on bottom for perfect alignment
- **Settings popover** — Click the menu bar icon to configure preferences
- **Toggle metrics** — Show or hide individual metrics (CPU, GPU, RAM, Disk, Network)
- **Refresh interval** — Choose from 1s, 2s, 5s, or 10s update intervals
- **Network units** — Select Kbps or Mbps for network speed display
- **Launch at Login** — Automatic startup via SMAppService
- **Native performance** — Pure Swift/SwiftUI with minimal resource footprint
- **macOS design** — UI consistent with macOS Tahoe aesthetics
- **Custom app icon** — Beautiful modern icon designed specifically for StaBar

## System Requirements

- **macOS 14 Sonoma** or later
- Apple Silicon (M1/M2/M3) recommended; Intel Macs supported

## Installation

1. Download `StaBar-1.0.0.dmg` from [GitHub Releases](../../releases)
2. Open the DMG and drag **StaBar.app** to your **Applications** folder
3. Launch StaBar from Applications

> **Note:** StaBar is not code-signed or notarized. On first launch, macOS may block the app. To allow it:
>
> **System Settings → Privacy & Security → scroll down → click "Open Anyway"**

## Building from Source

Requires **Xcode 15+** with the macOS 14 SDK.

```bash
git clone https://github.com/wpttt/stabar.git
cd stabar

# Build Release configuration
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -scheme StaBar \
  -configuration Release \
  SYMROOT=./build build

# Launch the app
open build/Release/StaBar.app
```

To run unit tests:

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  test -scheme StaBar -destination 'platform=macOS'
```

To create a DMG for distribution:

```bash
./scripts/create-dmg.sh
```

The DMG creation script automatically:
- Compiles the app
- Generates the app icon in all required sizes
- Applies the custom icon to the DMG file itself
- Sets the volume icon for the mounted DMG

## Usage

1. **Launch** — StaBar runs in the menu bar with no main window
2. **View metrics** — System metrics appear in the menu bar as independent columns
3. **Open settings** — Click the menu bar icon to open the settings popover
4. **Configure** — Toggle which metrics to display, set the refresh interval, and choose network speed units
5. **Auto-start** — Enable "Launch at Login" to start StaBar automatically on login

## Known Limitations

1. **GPU monitoring** uses the IOAccelerator private API, which may not be available on all systems. StaBar gracefully falls back to 0% if unavailable.
2. **Not code-signed** — Users must manually trust the app in System Settings on first launch.
3. **macOS 14+ only** — StaBar uses modern SwiftUI features introduced in macOS 14.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

- Inspired by [Stats](https://github.com/exelban/stats) by exelban — the most comprehensive macOS system monitor
- [Rectangle](https://github.com/rxhanson/Rectangle) by rxhanson — for menu bar and login item patterns
