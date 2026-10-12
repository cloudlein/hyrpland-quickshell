pragma Singleton
import QtQuick
import Quickshell
import "../.."

Item {
    id: root

    property bool open: false

    function toggle() {
        root.open = !root.open
    }

    function lock() {
        root.open = false
        LockManager.lock()
    }

    function suspend() {
        root.open = false
        Quickshell.execDetached(["systemctl", "suspend"])
    }

    function logout() {
        root.open = false
        Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
    }

    function reboot() {
        root.open = false
        Quickshell.execDetached(["systemctl", "reboot"])
    }

    function shutdown() {
        root.open = false
        Quickshell.execDetached(["systemctl", "poweroff"])
    }

    function execute(index) {
        if (index === 0) root.lock()
        else if (index === 1) root.suspend()
        else if (index === 2) root.logout()
        else if (index === 3) root.reboot()
        else if (index === 4) root.shutdown()
    }
}
