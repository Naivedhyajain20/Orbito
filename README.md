<div align="center">

# 🪐 Orbito
### The Next-Gen Dynamic Notch & System Command Center for macOS

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-black?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-007AFF?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-GPL%20v3-blue?style=for-the-badge)](LICENSE)

<p align="center">
  <b>Transform your MacBook's notch into an ultra-sleek, futuristic HUD.</b><br>
  Real-time kernel telemetry, Apple-grade storage breakdown, instant clipboard history, seamless file shelf, dynamic media controller, and productivity tools — all nestled seamlessly around your notch.
</p>

</div>

---

## ✨ Features

### ⚡ Real-Time System Telemetry & Activity Monitor
Directly tap into macOS Mach kernel APIs and hardware telemetry without heavy background overhead:
- **Live CPU Waveform**: Multi-core real-time CPU percentage with a rolling live waveform visualizer.
- **GPU & Core Engine**: Live GPU utilization and graphics memory metrics.
- **Memory (RAM) Diagnostics**: Detailed physical memory breakdown (*Active*, *Wired*, *Compressed*, and *Free*).
- **Network I/O Throughput**: Dynamic download and upload speeds with live transfer indicators.
- **Battery & Thermals**: Live battery percentage, charging wattage, cycle count, state of health, and SoC temperatures.

### 💾 Apple-Style Macintosh HD Storage Analyzer
- **Interactive Multi-Segment Storage Bar**: Accurate APFS capacity visualizer categorized into *Apps*, *Developer*, *iCloud Drive*, *macOS*, *System Data*, and *Free Space*.
- **Quick Actions**: One-click jump directly to native macOS Storage Management settings.

### 📋 Smart Clipboard Manager
- **Instant History**: Automatically tracks copied text and code snippets with instant preview.
- **Search & Filter**: Real-time fuzzy search to quickly find past clippings.
- **1-Click Copy**: Re-copy any snippet with instant visual feedback and relative timestamps.

### 📂 Notch File Tray & AirDrop Staging
- **Drag-and-Drop Shelf**: Drop any file onto the notch to temporarily hold it while switching workspaces or full-screen apps.
- **Drag Out Anywhere**: Seamlessly drag items from the notch tray onto Finder, Desktop, Mail, or Slack.
- **Instant AirDrop**: Quick AirDrop button to share staged files immediately with nearby Apple devices.

### 🎵 Dynamic Media Player & Audio Visualizer
- **Now Playing HUD**: Displays currently playing tracks from Apple Music, Spotify, YouTube Music, and web browsers.
- **Interactive Controls**: Scrubbing timeline, album art display, play/pause, next/previous buttons.
- **Audio Waveform**: Responsive visualizer reacting to live media playback.

### ⏱️ Focus, Calendar & Productivity Hub
- **Pomodoro Timer**: Clean timer with configurable intervals, audio cues, and active notch status badge.
- **Calendar & Agenda**: View upcoming meetings, events, and reminders directly from the notch.
- **Scratchpad & Notes**: Quick jotting area for notes and ideas.

### 🎛️ Minimalist Native HUD Replacements
- Modern, unobtrusive floating HUDs for **Volume**, **Display Brightness**, and **Keyboard Backlight**.

---

## 📸 Overview & Architecture

```
                      ┌───────────────────────────────────────┐
                      │             ORBITO NOTCH              │
  ┌───────────────────┴───────────────────────────────────────┴───────────────────┐
  │  [🎧 Media Player]   [📊 Activity HUD]   [💾 Storage]   [📋 Clipboard]   [📂 Tray]  │
  └───────────────────────────────────────────────────────────────────────────────┘
                                          │
       ┌──────────────────┬───────────────┴───────────────┬──────────────────┐
       ▼                  ▼                               ▼                  ▼
 [Mach Kernel APIs]   [IOKit / Power]             [AppKit / Pasteboard]   [APFS FileSystem]
 (CPU/RAM/GPU Load)   (Battery/Thermal)            (Clipboard Tracking)   (Storage Breakdown)
```

- **100% Native Swift & SwiftUI**: Crafted exclusively for macOS with zero heavy web wrappers or Electron bloat.
- **Low Energy Footprint**: Utilizes native Mach host statistics and event-driven updates to preserve battery life.
- **Screen Adaptive**: Automatically adapts across MacBook Pro liquid retina notch displays and external monitors without hardware notches.

---

## 📥 Download & Installation

1. **Download the latest release**:
   Grab **`Orbito.dmg`** from the [GitHub Releases](https://github.com/Naivedhyajain20/Orbito/releases) page.

2. **Install**:
   Open `Orbito.dmg` and drag **Orbito** into your `/Applications` folder.

3. **First-Time Launch (Gatekeeper)**:
   Because Orbito is independently built without a paid Apple Developer certificate, macOS may show a security notice on first launch. To bypass this instantly, run this one-line command in Terminal:
   ```bash
   xattr -cr /Applications/Orbito.app
   ```
   Then double-click **Orbito** in Applications to launch!

---

## 🚀 Building from Source

### System Requirements
- **macOS**: macOS 14.0 Sonoma or macOS 15.0+ Sequoia (Apple Silicon & Intel)
- **Xcode**: 15.0 or later
- **Swift**: 5.9+

### Building from Source

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Naivedhyajain20/Orbito.git
   cd Orbito
   ```

2. **Open in Xcode**:
   ```bash
   open boringNotch.xcodeproj
   ```

3. **Build & Run**:
   - Select the `boringNotch` scheme and press **`⌘ + R`** to launch Orbito.
   - On first launch, follow the onboarding screen to grant necessary permissions (Accessibility & Calendar).

---

## ⌨️ Gestures & Controls

| Action | Interaction |
| :--- | :--- |
| **Expand Notch HUD** | Hover your cursor over the notch area |
| **Switch Panels** | Click on any icon in the Notch Nest bar (System, Storage, Clipboard, Tray, Timer) |
| **Stash Files** | Drag any file into the notch from Finder |
| **Open Settings** | Click the Orbito icon in the macOS Menu Bar → **Settings** (or press `⌘ ,`) |

---

## 🔒 Privacy & Security

- **100% Local & Offline**: Orbito operates entirely on your Mac. No telemetry is collected, and no data ever leaves your device.
---

## 📄 License

Orbito is licensed under the [GNU General Public License v3.0](LICENSE).
