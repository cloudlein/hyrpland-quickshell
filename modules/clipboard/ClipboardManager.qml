pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool open: false
    property var history: []
    property string searchText: ""
    property int selectedIndex: 0

    readonly property string helperPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/clipboard-helper.py"

    // Background watcher: captures every copy automatically via wl-paste
    Process {
        id: watcherProc
        command: ["wl-paste", "--watch", root.helperPath, "record"]
        running: true
    }

    // Process to reload clipboard list
    Process {
        id: listProc
        command: [root.helperPath, "list"]
        stdout: StdioCollector {
            onDataChanged: {
                try {
                    let items = JSON.parse(text)
                    root.history = items || []
                } catch(e) {
                    root.history = []
                }
            }
        }
    }

    function toggle() {
        if (root.open) {
            closePicker()
        } else {
            openPicker()
        }
    }

    function openPicker() {
        root.searchText = ""
        root.selectedIndex = 0
        listProc.running = true
        root.open = true
    }

    function closePicker() {
        root.open = false
    }

    function copyItem(id) {
        Quickshell.execDetached([root.helperPath, "copy", id.toString()])
        root.closePicker()
    }

    function deleteItem(id) {
        Quickshell.execDetached([root.helperPath, "delete", id.toString()])
        listProc.running = true
    }

    function clearAll() {
        Quickshell.execDetached([root.helperPath, "clear"])
        root.history = []
        root.closePicker()
    }

    Component.onCompleted: {
        listProc.running = true
    }
}
