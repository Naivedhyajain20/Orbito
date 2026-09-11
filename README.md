<div align="center">

# 🪐 Orbito
### The Ultimate Next-Gen Dynamic Notch & System Command Center for macOS

[![macOS](https://img.shields.io/badge/macOS-14.0%2B%20%7C%2015.0%2B%20Sonoma%20%26%20Sequoia-black?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com/macos)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%20%7C%20M2%20%7C%20M3%20%7C%20M4-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native%20Architecture-007AFF?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Privacy First](https://img.shields.io/badge/Privacy-100%25%20Local%20%26%20Offline-34C759?style=for-the-badge&logo=shield&logoColor=white)](#-privacy--security)

<p align="center">
  <b>Elevate your MacBook display into a hyper-responsive, futuristic command island.</b><br>
  Real-time Mach kernel telemetry, 3D Gyroscope Face ID unlock with haptics & Apple Pay audio, intelligent APFS storage breakdown, instant clipboard memory, drag-and-drop file tray, seamless media controller, and screen capture privacy shield — elegantly nestled around your notch.
</p>

[Download Latest Release](https://github.com/Naivedhyajain20/Orbito/releases) • [Features](#-core-features) • [Installation](#-download--installation) • [Architecture](#-architecture--engineering) • [Privacy](#-privacy--security)

</div>

---

## 🌟 Why Orbito?

MacBook displays feature a physical notch that is often treated as dead space. **Orbito** transforms that space into a context-aware powerhouse of utility, hardware monitoring, and instant productivity — engineered in **100% Native Swift & SwiftUI** with zero Electron overhead.

```
                              ╔═══════════════════════════╗
                              ║       O R B I T O         ║
 ╔════════════════════════════╩═══════════════════════════╩════════════════════════════╗
 ║  [⚡ Activity HUD]  [🪪 Face ID]  [💾 Storage]  [📋 Clipboard]  [📂 Tray]  [🎵 Media]  ║
 ╚══════════════════════════════════════════════════════════════════════════════════════╝
                                            │
        ┌───────────────────┬───────────────┴───────────────┬───────────────────┐
        ▼                   ▼                               ▼                   ▼
 [Mach Kernel APIs]  [SkyLight / Window]            [IOKit / Power]     [APFS FileSystem]
  (CPU/RAM/GPU Load)  (Screen Privacy Filter)        (Battery Telemetry) (Storage Breakdown)
```

---

## ✨ Core Features

### 🪪 1. Dynamic Face ID & Gyroscope Unlock Experience
Experience an iPhone-style Dynamic Island unlock animation right at your MacBook notch:
- **3D Glowing Gyroscope Rings**: Smooth mint-green gyro rings rotate in 3D perspective upon device unlock.
- **Success Checkmark (`✓`) & Apple Pay Sound**: Crisp Apple Pay haptic chime triggers the moment Touch ID or password authentication succeeds.
- **Granular Customization**: Toggle unlock animation, Apple Pay sound effect, and haptic feedback individually in **Settings > General**.

---

### 🛡️ 2. Screen Capture & Recording Privacy Shield
Keep your workspace clean and your sensitive clippings private during meetings, tutorials, and screen shares:
- **Auto-Hide on Screenshots & Screen Recording**: Uses macOS window server level sharing restrictions (`sharingType = .none`) to automatically make Orbito invisible in screenshots, QuickTime recordings, OBS, Zoom, and Google Meet.
- **User Selectable**: Easily toggle visibility under **Settings > General > System features** (Default: **Hidden**).

---

### ⚡ 3. Real-Time Mach-Kernel Telemetry & Hardware Activity HUD
Direct hardware instrumentation with sub-millisecond polling accuracy and ultra-low CPU footprint:
- **Live CPU Waveform**: Multi-core real-time utilization graphs with dynamic rolling waveform visualizer.
- **GPU & Neural Core Engine**: GPU load metrics and VRAM diagnostics.
- **Physical RAM Breakdown**: Color-coded breakdown of *Active*, *Wired*, *Compressed*, and *Free* physical memory.
- **Network Bandwidth Throughput**: Real-time upload and download speeds with live transfer indicators.
- **Battery & Thermal State**: Live percentage, charging wattage, battery cycle count, battery health, and SoC temperature sensors.

---

### 💾 4. Apple-Grade APFS Storage Visualizer
Instant, color-coded capacity inspector mirroring Apple's native macOS Storage layout:
- **Multi-Segment Capacity Bar**: Dynamic storage categorization including *Applications*, *Developer Tools*, *iCloud Drive*, *macOS Core*, *System Data*, and *Available Space*.
- **Quick Action Links**: One-click direct shortcut to native macOS Storage Management.

---

### 📋 5. Smart Clipboard Manager & Search
Never lose a copied link, code snippet, or text again:
- **Zero-Latency Clipboard Cache**: Automatically captures copy events in the background.
- **Real-Time Fuzzy Filter**: Instantly search through clipboard history with live keyword matching.
- **1-Click Restore**: Paste or re-copy any previous clipping with instant visual confirmation.

---

### 📂 6. Notch File Tray & AirDrop Staging Station
Your temporary file launchpad across spaces and full-screen windows:
- **Drag-and-Drop Stashing**: Drag files, photos, or documents directly into the notch to hold them temporarily while navigating between apps or desktops.
- **Drag Out Anywhere**: Seamlessly extract staged files into Mail, Slack, Terminal, or Finder.
- **One-Tap AirDrop**: Direct button to instantly beam staged files to nearby iOS and macOS devices.

---

### 🎵 7. Dynamic Media Controller & Waveform HUD
Control audio playback effortlessly without switching active apps:
- **Universal Player Support**: Integrates with Apple Music, Spotify, YouTube Music, Podcasts, and web browsers.
- **Full Playback Controls**: Interactive scrubber bar, track artwork, volume level, previous/next track, and pause/resume.
- **Dynamic Audio Waveform**: Responsive audio spectrum animation that pulses with music playback.

---

### ⏱️ 8. Pomodoro Focus & Productivity Suite
- **Customizable Intervals**: Configurable work/break durations with smooth notch status badges.
- **Audio & Haptic Alerts**: Non-distracting notifications when focus sessions complete.
- **Calendar & Quick Notes**: Preview upcoming meetings, calendar agenda, and a quick scratchpad.

---

### 🎛️ 9. Minimalist Native HUD Replacements
- Floating, transparent bezel-free indicators for **Volume**, **Display Brightness**, and **Keyboard Backlight**.

---

## 📥 Download & Installation

### Option A: Pre-Compiled Release (Recommended)

1. Download **[`boringNotch.dmg`](https://github.com/Naivedhyajain20/Orbito/releases)** or **[`boringNotch-Release.zip`](https://github.com/Naivedhyajain20/Orbito/releases)** from the latest release.
2. Open `boringNotch.dmg` and drag **Orbito** into your `/Applications` folder.
3. **First Launch (macOS Gatekeeper)**:
   Since Orbito is built independently without an Apple Developer certificate, macOS Gatekeeper may show a verification notice. Run this single command in Terminal to authorize:
   ```bash
   xattr -cr /Applications/boringNotch.app
   ```
4. Double-click **Orbito** to launch!

---

### Option B: Build from Source

#### Prerequisites
- macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- Xcode 15.0+
- Swift 5.9+

```bash
# 1. Clone the repository
git clone https://github.com/Naivedhyajain20/Orbito.git
cd Orbito

# 2. Open project in Xcode
open boringNotch.xcodeproj

# 3. Build & Run
# Select the 'boringNotch' scheme and press ⌘ + R
```

---

## ⌨️ Gestures & Shortcuts

| Action | Gesture / Shortcut | Description |
| :--- | :--- | :--- |
| **Expand Notch** | Hover cursor over notch | Opens the active command island |
| **Close Notch** | Two-finger swipe up / Move cursor away | Seamlessly snaps notch closed |
| **Stage Files** | Drag file onto Notch | Stashes file in Notch File Tray |
| **Quick Settings** | Click Menu Bar Icon → **Settings** (`⌘ ,`) | Opens configuration center |
| **Test Face ID** | Settings → **Test Face ID Animation** | Plays 3D gyro animation & Apple Pay sound |

---

## 🏗️ Architecture & Engineering

Orbito is built with a hyper-optimized native pipeline:

- **SkyLight Window Server Integration**: Custom `BoringNotchSkyLightWindow` implementation maintaining persistent floating window levels, space transitions, and recording privacy filters.
- **Mach Host Kernel Telemetry**: Directly queries low-level `host_statistics64` and `processor_info` Mach kernel APIs for near-zero CPU footprint (<0.1% idle).
- **CoreAudio & AVFoundation Engine**: Native `AVAudioPlayer` and `NSSound` dispatch for instant audio feedback without playback contention.
- **SwiftUI + AppKit Hybrid**: Smooth 60/120 FPS ProMotion spring animations with fine-grained state management via Swift `Defaults`.

---

## 🔒 Privacy & Security

- **100% Local Execution**: Orbito contains **zero trackers, zero analytics, and zero remote network calls**.
- **All Data Stays on Device**: Clipboard history, notes, and staged files exist strictly in your local memory and sandbox.
- **Open Source Transparency**: Every line of code is fully open and auditable.

---

<div align="center">

Crafted with ❤️ for macOS power users.

⭐ **Star this repository if you love Orbito!**

</div>
