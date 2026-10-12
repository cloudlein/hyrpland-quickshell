import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../.."

Rectangle {
    id: root

    property var notifData: null
    readonly property var itemData: notifData ? notifData : (typeof modelData !== "undefined" ? modelData : null)

    readonly property bool isWhatsApp: {
        if (!itemData) return false;
        let appName = (itemData.appName || "").toLowerCase();
        let appIcon = (itemData.appIcon || "").toLowerCase();
        let desktop = (itemData.desktopEntry || "").toLowerCase();
        let sum = (itemData.summary || "").trim();
        let body = (itemData.body || "").toLowerCase();

        if (appName.includes("whatsapp") || appIcon.includes("whatsapp") || desktop.includes("whatsapp")) return true;
        if (sum.toLowerCase().includes("whatsapp") || body.includes("whatsapp")) return true;

        if (itemData.hints) {
            for (let k in itemData.hints) {
                let val = String(itemData.hints[k] || "").toLowerCase();
                if (val.includes("whatsapp")) return true;
            }
        }

        // Check if summary matches a phone number (e.g. +62..., 08...)
        let phoneRegex = /^\+?[0-9][0-9\s\-\(\)\.]{5,20}$/;
        if (phoneRegex.test(sum)) return true;

        return false;
    }

    readonly property var parsedContent: {
        if (!itemData) return { summary: "", body: "" };
        let rawSummary = (itemData.summary || "").trim();
        let rawBody = (itemData.body || "").trim();

        if (root.isWhatsApp) {
            let sumLower = rawSummary.toLowerCase();
            if (sumLower === "whatsapp" || sumLower === "whatsapp web" || sumLower === "web.whatsapp.com") {
                let colonIdx = rawBody.indexOf(":\n");
                if (colonIdx === -1) colonIdx = rawBody.indexOf(": ");
                if (colonIdx !== -1) {
                    return {
                        summary: rawBody.substring(0, colonIdx).trim(),
                        body: rawBody.substring(colonIdx + 2).trim()
                    };
                }
                let nlIdx = rawBody.indexOf("\n");
                if (nlIdx !== -1) {
                    return {
                        summary: rawBody.substring(0, nlIdx).trim(),
                        body: rawBody.substring(nlIdx + 1).trim()
                    };
                }
            }
        }

        return {
            summary: rawSummary,
            body: rawBody
        };
    }

    width: parent ? parent.width : 380
    implicitHeight: contentCol.implicitHeight + 20
    radius: 14
    color: cardMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container
    border.color: Theme.outline_variant
    border.width: 1
    clip: true

    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.itemData && root.itemData.actions && root.itemData.actions.length > 0) {
                let defaultAction = root.itemData.actions.find(a => a.identifier === "default") || root.itemData.actions[0]
                if (defaultAction) {
                    try { defaultAction.invoke() } catch(e) {}
                }
            }
        }
    }

    Column {
        id: contentCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 6

        // Top Row: App Icon + App Name + Time + Close
        RowLayout {
            width: parent.width

            Rectangle {
                width: 20
                height: 20
                radius: 5
                color: Theme.surface_container_high
                clip: true

                IconImage {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    visible: !root.isWhatsApp && source.toString().length > 0
                    source: (root.itemData && root.itemData.appIcon) ? (Quickshell.iconPath(root.itemData.appIcon) || root.itemData.appIcon) : ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.isWhatsApp || (!root.itemData || !root.itemData.appIcon)
                    text: root.isWhatsApp ? "󰖣" : "󰂚"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: root.isWhatsApp ? "#25D366" : Theme.primary
                }
            }

            Text {
                text: root.isWhatsApp ? "WhatsApp" : ((root.itemData && root.itemData.appName) || "System")
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: root.isWhatsApp ? "#25D366" : Theme.on_surface_variant
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: root.itemData ? NotificationManager.formatTime(root.itemData.id) : ""
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.outline
            }

            // Dismiss Button
            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: dismissMouse.containsMouse ? Theme.surface_container_high : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: dismissMouse.containsMouse ? Theme.error : Theme.outline
                }

                MouseArea {
                    id: dismissMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        try {
                            if (root.itemData) root.itemData.dismiss()
                        } catch(e) {}
                    }
                }
            }
        }

        // Summary
        Text {
            width: parent.width
            visible: text.length > 0
            text: root.parsedContent.summary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
            color: Theme.on_surface
            elide: Text.ElideRight
        }

        // Body
        Text {
            width: parent.width
            visible: text.length > 0
            text: root.parsedContent.body
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.on_surface_variant
            wrapMode: Text.Wrap
            textFormat: Text.StyledText
            maximumLineCount: 6
            elide: Text.ElideRight
        }

        // Image
        Image {
            width: parent.width
            height: (!root.isWhatsApp && status === Image.Ready) ? 100 : 0
            visible: !root.isWhatsApp && status === Image.Ready
            source: (!root.isWhatsApp && root.itemData && root.itemData.image) || ""
            fillMode: Image.PreserveAspectCrop
            mipmap: true
            asynchronous: true
        }

        // Actions
        Row {
            width: parent.width
            spacing: 6
            visible: root.itemData && root.itemData.actions && root.itemData.actions.length > 0

            Repeater {
                model: root.itemData ? root.itemData.actions : []
                delegate: Rectangle {
                    required property var modelData
                    height: 24
                    radius: 7
                    implicitWidth: actLabel.implicitWidth + 14
                    color: actMouse.containsMouse ? Theme.primary : Theme.surface_container_high
                    border.color: Theme.outline_variant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        id: actLabel
                        anchors.centerIn: parent
                        text: modelData.text || modelData.identifier
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: actMouse.containsMouse ? Theme.on_primary : Theme.on_surface
                    }

                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            try {
                                modelData.invoke()
                            } catch(e) {}
                        }
                    }
                }
            }
        }
    }
}
