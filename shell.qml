import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."
import "./modules" as Modules
import "./modules/notifications" as Notifications

import "./modules/launcher" as Launcher
import "./modules/wallpaper" as Wallpaper
import "./modules/lockscreen" as Lockscreen
import "./modules/osd" as OSD
import "./modules/session" as Session
import "./modules/clipboard" as Clipboard

ShellRoot {
    // IPC Handler for Wallpaper Picker
    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            WallpaperManager.toggle()
        }

        function open(): void {
            WallpaperManager.openPicker()
        }

        function close(): void {
            WallpaperManager.cancelPicker()
        }

        function next(): void {
            WallpaperManager.next()
        }

        function prev(): void {
            WallpaperManager.prev()
        }

        function apply(): void {
            WallpaperManager.applyCurrent()
        }
    }

    // IPC Handler for App Launcher
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            LauncherManager.toggle()
        }

        function open(): void {
            LauncherManager.openLauncher()
        }

        function close(): void {
            LauncherManager.closeLauncher()
        }
    }

    // IPC Handler for CLI, hotkeys, and scripts
    IpcHandler {
        target: "notifications"

        function toggle(): void {
            NotificationManager.toggleControlCenter()
        }

        function open(): void {
            NotificationManager.openControlCenter()
        }

        function close(): void {
            NotificationManager.closeControlCenter()
        }

        function toggleDnd(): void {
            NotificationManager.toggleDnd()
        }

        function clear(): void {
            NotificationManager.clearAll()
        }
    }

    // IPC Handler for Lockscreen
    IpcHandler {
        target: "lockscreen"

        function lock(): void {
            LockManager.lock()
        }

        function unlock(): void {
            LockManager.unlock()
        }

        function toggle(): void {
            LockManager.toggle()
        }
    }

    // IPC Handler for Session / Power Menu
    IpcHandler {
        target: "session"

        function toggle(): void {
            Session.SessionManager.toggle()
        }

        function lock(): void {
            Session.SessionManager.lock()
        }

        function suspend(): void {
            Session.SessionManager.suspend()
        }

        function logout(): void {
            Session.SessionManager.logout()
        }

        function reboot(): void {
            Session.SessionManager.reboot()
        }

        function shutdown(): void {
            Session.SessionManager.shutdown()
        }
    }

    // IPC Handler for Clipboard Manager
    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            Clipboard.ClipboardManager.toggle()
        }

        function open(): void {
            Clipboard.ClipboardManager.openPicker()
        }

        function close(): void {
            Clipboard.ClipboardManager.closePicker()
        }
    }

    // IPC Handler for OSD
    IpcHandler {
        target: "osd"

        function brightnessUp(): void {
            OSD.OSDManager.brightnessUp()
        }

        function brightnessDown(): void {
            OSD.OSDManager.brightnessDown()
        }
    }


    // Lockscreen
    Lockscreen.LockScreen {}

    // Wallpaper Background Layer (Native Wallpaper Engine)
    Wallpaper.WallpaperBackground {}

    // Wallpaper Picker Window
    Wallpaper.WallpaperPicker {}

    // App Launcher Window
    Launcher.AppLauncher {}

    // Floating Notification Popups (Toast banners)
    Notifications.NotificationToasts {}

    // Slide-in Control Center (Notifications & Quick Settings)
    Notifications.ControlCenter {}

    // On-Screen Display (Volume & Brightness OSD Popup)
    OSD.OSDPopup {}

    // System Session / Power Menu Dialog
    Session.SessionMenu {}

    // Clipboard History Manager Window
    Clipboard.ClipboardPicker {}


    PanelWindow {
        id: bar
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 35
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-bar"
        WlrLayershell.exclusiveZone: 35

        Item {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 4
            anchors.bottomMargin: 3

            // Left Modules
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Modules.Workspaces {}
                Modules.Timer {}
                Modules.Music {}
            }

            // Center Module (Jam | Spectrum Audio | Cuaca)
            Modules.Center {
                anchors.centerIn: parent
            }

            // Right Modules
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Modules.Temperature {}
                Modules.Prayer {}
                Modules.Audio {}
                Modules.Notification {}
            }
        }
    }
}
