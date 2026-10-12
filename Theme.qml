pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property color background: "#19120c"
    property color surface: "#19120c"
    property color surface_container: "#29211b"
    property color surface_container_high: "#342c25"
    property color primary: "#ffb878"
    property color on_primary: "#3f2000"
    property color secondary_fixed_dim: "#e2c0a5"
    property color on_surface: "#f4e4da"
    property color on_surface_variant: "#d6c3b6"
    property color outline: "#a49387"
    property color outline_variant: "#706257"
    property color error: "#ffb4ab"
    property color on_error: "#580003"
    property color error_container: "#93000a"
    property color on_error_container: "#ffdad6"
    property color primary_container: "#5c3000"
    property color on_primary_container: "#ffdcbe"
    property color surface_container_highest: "#403730"
    property string fontFamily: "JetBrainsMono Nerd Font"

    function applyJson(raw) {
        try {
            let c = JSON.parse(raw)
            if (c.background) root.background = c.background
            if (c.surface) root.surface = c.surface
            if (c.surface_container) root.surface_container = c.surface_container
            if (c.surface_container_high) root.surface_container_high = c.surface_container_high
            if (c.primary) root.primary = c.primary
            if (c.on_primary) root.on_primary = c.on_primary
            if (c.secondary_fixed_dim) root.secondary_fixed_dim = c.secondary_fixed_dim
            if (c.on_surface) root.on_surface = c.on_surface
            if (c.on_surface_variant) root.on_surface_variant = c.on_surface_variant
            if (c.outline) root.outline = c.outline
            if (c.outline_variant) root.outline_variant = c.outline_variant
            if (c.error) root.error = c.error
            if (c.on_error) root.on_error = c.on_error
        } catch(e) {}
    }

    property var fileView: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        preload: true
        watchChanges: true
        onTextChanged: root.applyJson(text())
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (fileView) {
                fileView.reload()
                root.applyJson(fileView.text())
            }
        }
    }

    Component.onCompleted: {
        if (fileView && fileView.text().length > 0) {
            root.applyJson(fileView.text())
        }
    }
}
