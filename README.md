# StaBar

A lightweight native macOS menu bar system monitor built with Swift and SwiftUI.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)

## Features

- **Real-time monitoring** — CPU, GPU, RAM, Disk, and Network metrics at a glance
- **Compact display** — All metrics shown directly in the menu bar: `C 42% G 15% R 68% D 95% ↑1.2 ↓3.4`
- **Settings popover** — Click the menu bar icon to configure preferences
- **Toggle metrics** — Show or hide individual metrics (CPU, GPU, RAM, Disk, Network)
- **Refresh interval** — Choose from 1s, 2s, 5s, or 10s update intervals
- **Network units** — Select auto, KB/s, or MB/s for network speed display
- **Launch at Login** — Automatic startup via SMAppService
- **Native performance** — Pure Swift/SwiftUI with minimal resource footprint
- **macOS design** — UI consistent with macOS Tahoe aesthetics

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
git clone https://github.com/user/stabar.git
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

## Usage

1. **Launch** — StaBar runs in the menu bar with no main window
2. **View metrics** — System metrics appear directly in the menu bar text
3. **Open settings** — Click the menu bar icon to open the settings popover
4. **Configure** — Toggle which metrics to display, set the refresh interval, and choose network speed units
5. **Auto-start** — Enable "Launch at Login" to start StaBar automatically on login

## Screenshots

<!-- TODO: Add screenshots after v1.0 release -->

*Screenshots will be added after the v1.0 release.*

## Architecture

```
StaBar/
├── StaBarApp.swift              # App entry point, MenuBarExtra setup
├── ContentView.swift            # Root content view
├── PreferencesStore.swift       # UserDefaults-backed settings store
├── Services/
│   ├── MetricsService.swift     # Metric reader protocol definition
│   ├── CPUReader.swift          # CPU usage via host_statistics64
│   ├── GPUReader.swift          # GPU usage via IOAccelerator
│   ├── RAMReader.swift          # RAM usage via vm_statistics64
│   ├── DiskReader.swift         # Disk usage via statfs
│   ├── NetReader.swift          # Network throughput via getifaddrs
│   └── LaunchAtLogin.swift      # Login item via SMAppService
├── Views/
│   ├── MenuBarView.swift        # Main popover container
│   ├── CompactStatusView.swift  # Menu bar compact text formatter
│   └── SettingsView.swift       # Settings UI with toggles and pickers
└── ViewModels/
    └── MetricsViewModel.swift   # @Observable model binding metrics to UI
```

## Known Limitations

1. **GPU monitoring** uses the IOAccelerator private API, which may not be available on all systems. StaBar gracefully falls back to 0% if unavailable.
2. **Not code-signed** — Users must manually trust the app in System Settings on first launch.
3. **macOS 14+ only** — StaBar uses the `MenuBarExtra` API introduced in macOS 14.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

- Inspired by [Stats](https://github.com/exelban/stats) by exelban — the most comprehensive macOS system monitor
- [Rectangle](https://github.com/rxhanson/Rectangle) by rxhanson — for menu bar and login item patterns
