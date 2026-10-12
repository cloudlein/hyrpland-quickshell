# Quickshell Desktop Configuration

A modular desktop shell configuration built with [Quickshell](https://quickshell.outfoxxed.me/) for Wayland compositors (specifically optimized for Hyprland). This configuration provides a complete desktop interface including an application bar, launcher, notification daemon, control center, on-screen display (OSD), clipboard manager, audio visualizer, wallpaper manager with custom GLSL transition shaders, and a native PAM lockscreen.

---

## Architecture Overview

The configuration is organized modularly with a single root entry point (`shell.qml`) delegating lifecycle and interface state to dedicated manager singletons and module components:

```
~/.config/quickshell/
├── shell.qml                      # Root entry point and panel orchestration
├── Theme.qml                      # Design tokens and dynamic color definitions
├── LauncherManager.qml            # App launcher window management
├── NotificationManager.qml        # Notification daemon and IPC handler
├── LockManager.qml                # Lockscreen session lifecycle and PAM auth
├── WallpaperManager.qml           # Wallpaper switching and transition controller
├── colors.json                    # Generated Material You palette (JSON format)
├── colors.css                     # Generated Material You palette (CSS variables)
├── cava.conf                      # Cava audio visualizer configuration
├── components/
│   └── Pill.qml                   # Shared pill container UI component
├── modules/
│   ├── Center.qml                 # Primary status bar container
│   ├── Clock.qml                  # Time and calendar module
│   ├── Workspaces.qml             # Hyprland active workspaces indicator
│   ├── Music.qml                  # Media player controller (MPRIS)
│   ├── Weather.qml                # Weather status module (Open-Meteo)
│   ├── Prayer.qml                 # Prayer schedule module (Aladhan API)
│   ├── Temperature.qml            # Hardware temperature sensor monitor
│   ├── Audio.qml                  # PulseAudio / PipeWire volume control
│   ├── Spectrum.qml               # Cava-driven audio spectrum visualizer
│   ├── Timer.qml                  # Countdown timer module
│   ├── Notification.qml           # Notification status icon in panel
│   ├── clipboard/                 # Clipboard history manager and popup picker
│   ├── launcher/                  # Application launcher interface
│   ├── lockscreen/                # Fullscreen PAM authentication lockscreen
│   ├── notifications/             # Notification toasts and Control Center
│   ├── osd/                       # On-screen display for volume and brightness
│   ├── session/                   # Power and session control menu
│   └── wallpaper/                 # Wallpaper background and picker with GLSL shader
└── scripts/
    ├── apply-wallpaper.sh         # Wallpaper cache, Matugen sync, and theme reload
    ├── cava.sh                    # Cava FIFO pipe handler
    ├── clipboard-helper.py        # Clipboard history persistence (wl-clipboard)
    ├── music.sh                   # Playerctl wrapper for media status
    ├── prayer.sh                  # Prayer calculation script
    ├── revert-sddm.sh             # Utility script to restore SDDM service
    ├── setup-lock-on-boot.sh      # TTY1 autologin setup for lock-on-boot workflow
    ├── swaync-client              # Drop-in compatibility client routing to Quickshell IPC
    ├── temperature.sh             # Temperature aggregation script
    ├── timer.sh                   # Timer execution script
    ├── timer-cancel.sh            # Timer cancellation script
    └── weather.sh                 # Weather polling script
```

---

## Features

### Status Bar and Modules
- **Dynamic Workspaces**: Synchronized with Hyprland workspace state.
- **Media Player**: Track metadata, playback state, and controls backed by `playerctl`.
- **Weather Display**: Current temperature and meteorological condition from Open-Meteo with 5-second query timeouts and local caching.
- **Prayer Schedule**: Calculates remaining time to next prayer with Aladhan API (Kemenag RI method) and daily local cache.
- **Audio Spectrum**: Live audio frequency visualizer fed by Cava via an asynchronous FIFO stream.
- **Hardware Sensors**: CPU and GPU temperature aggregation.
- **Quick Timer**: Timer configuration with notification integration.

### Desktop Services and Overlays
- **Application Launcher**: Fuzzy search over desktop applications with category classification.
- **Notification Center and Toasts**: In-process notification server with grouping, Do-Not-Disturb mode, and historical log.
- **OSD**: Animated on-screen indicators for volume and backlight adjustments.
- **Clipboard History**: Persistent clipboard history backed by `wl-clipboard` and a Python helper (`scripts/clipboard-helper.py`).
- **Wallpaper Engine**: Hardware-accelerated wallpaper transitions utilizing custom fragment shaders (`transition.frag` compiled to Qt Shader Binary `transition.frag.qsb`). Integrated with `matugen` for dynamic Material You system palette generation.
- **Lock Screen**: Native Wayland lockscreen with direct PAM authentication (`LockScreen.qml`), eliminating external lockscreen dependencies.
- **Session Menu**: Fast access to Lock, Suspend, Hibernate, Reboot, and Shutdown actions.

---

## Dependencies

Ensure the following packages and tools are installed on your system:

### Core Runtime
- `quickshell` (Wayland Qt Quick desktop shell)
- `hyprland` (Wayland compositor)
- `qt6-declarative`, `qt6-shadertools`

### Utilities and Daemons
- `playerctl` (MPRIS media control)
- `cava` (Console audio visualizer)
- `wl-clipboard` (Wayland clipboard utilities: `wl-copy`, `wl-paste`)
- `jq` (Command-line JSON processor)
- `curl` (Data retrieval for weather and prayer APIs)
- `python3` (Required for clipboard persistence daemon)
- `matugen` (Optional, for automatic Material You palette generation from wallpaper)
- `libnotify` / `notify-send` (Desktop notification events)

### Typography
- A Nerd Font (e.g., `JetBrainsMono Nerd Font`) for interface glyphs and weather/status icons.

---

## Installation

1. Clone this repository into your user configuration directory:
   ```bash
   git clone https://github.com/cloudlein/quickshell-config.git ~/.config/quickshell
   ```

2. Make all helper scripts executable:
   ```bash
   chmod +x ~/.config/quickshell/scripts/*
   ```

3. Ensure Qt Shader Binary is present or recompile the shader if necessary:
   ```bash
   qsb --glsl "330,120" --hlsl 50 --msl 12 -o ~/.config/quickshell/modules/wallpaper/transition.frag.qsb ~/.config/quickshell/modules/wallpaper/transition.frag
   ```

---

## Integration with Hyprland

Add the following autostart commands to your `~/.config/hypr/hyprland.conf`:

```ini
# Start Quickshell on login
exec-once = quickshell

# Start Clipboard listener
exec-once = wl-paste --type text --watch ~/.config/quickshell/scripts/clipboard-helper.py record
```

### Keybind Suggestions

Configure key bindings in `~/.config/hypr/hyprland.conf` to trigger Quickshell windows via IPC:

```ini
# App Launcher
bind = $mainMod, SPACE, exec, quickshell ipc call launcher toggle

# Notification Center
bind = $mainMod, N, exec, quickshell ipc call notifications toggle

# Clipboard History Picker
bind = $mainMod, V, exec, quickshell ipc call clipboard toggle

# Wallpaper Selector
bind = $mainMod, W, exec, quickshell ipc call wallpaper toggle

# Session / Power Menu
bind = $mainMod, ESCAPE, exec, quickshell ipc call session toggle

# Lock Screen
bind = $mainMod, L, exec, quickshell ipc call lock lock
```

---

## IPC Interface Reference

Quickshell exposes inter-process communication (IPC) targets callable via `quickshell ipc call <target> <action>`:

| Target | Method | Description |
| :--- | :--- | :--- |
| `launcher` | `toggle` | Opens or closes the application launcher |
| `notifications` | `toggle` | Toggles the notification Control Center |
| `notifications` | `toggleDnd` | Toggles Do Not Disturb mode |
| `notifications` | `clear` | Clears all current notifications |
| `clipboard` | `toggle` | Toggles the clipboard history selector |
| `wallpaper` | `toggle` | Toggles the wallpaper picker overlay |
| `session` | `toggle` | Toggles the session / power menu |
| `lock` | `lock` | Triggers the native PAM lockscreen |

---

## Lock-on-Boot Setup (Optional)

For systems using direct TTY autologin into Hyprland without a display manager (such as SDDM), the script `scripts/setup-lock-on-boot.sh` automates the TTY1 autologin override and locks the session upon initial desktop loading.

To apply:
```bash
sudo ~/.config/quickshell/scripts/setup-lock-on-boot.sh
```

To revert back to SDDM:
```bash
sudo ~/.config/quickshell/scripts/revert-sddm.sh
```
