import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../.."

Rectangle {
    id: root

    required property var notifData
    readonly property var itemData: notifData

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

    width: 380
    implicitHeight: contentCol.implicitHeight + 24
    radius: 16
    color: Theme.surface_container_high
    border.color: Theme.outline_variant
    border.width: 1
    clip: true

    // Hover effect
    property bool isHovered: cardMouse.containsMouse

    // Entrance animation
    opacity: 0
    transform: Translate { id: trans; x: 50 }

    Component.onCompleted: {
        entranceAnim.start()
    }

    ParallelAnimation {
        id: entranceAnim
        NumberAnimation { target: root; property: "opacity"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: trans; property: "x"; to: 0; duration: 250; easing.type: Easing.OutCubic }
    }

    // Auto-dismiss timer (paused on hover or critical urgency)
    Timer {
        id: autoDismissTimer
        interval: root.notifData.expireTimeout > 0 ? root.notifData.expireTimeout : 6000
        running: !root.isHovered && root.notifData.urgency !== 2
        onTriggered: {
            NotificationManager.removeToast(root.notifData.id)
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // If default action exists, trigger it; else dismiss toast
            if (root.notifData.actions && root.notifData.actions.length > 0) {
                let defaultAction = root.notifData.actions.find(a => a.identifier === "default") || root.notifData.actions[0]
                if (defaultAction) {
                    try { defaultAction.invoke() } catch(e) {}
                }
            }
            NotificationManager.removeToast(root.notifData.id)
        }
    }

    Column {
        id: contentCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 8

        // Top Header Row
        RowLayout {
            width: parent.width

            // App Icon
            Rectangle {
                width: 22
                height: 22
                radius: 6
                color: Theme.surface_container
                clip: true

                IconImage {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    visible: !root.isWhatsApp && source.toString().length > 0
                    source: root.notifData.appIcon ? (Quickshell.iconPath(root.notifData.appIcon) || root.notifData.appIcon) : ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.isWhatsApp || !root.notifData.appIcon
                    text: root.isWhatsApp ? "󰖣" : "󰂚"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: root.isWhatsApp ? "#25D366" : Theme.primary
                }
            }

            // App Name
            Text {
                text: root.isWhatsApp ? "WhatsApp" : (root.notifData.appName || "Notification")
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: root.isWhatsApp ? "#25D366" : Theme.on_surface_variant
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Close button
            Rectangle {
                width: 22
                height: 22
                radius: 11
                color: closeMouse.containsMouse ? Theme.surface_container : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: closeMouse.containsMouse ? Theme.error : Theme.outline
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        NotificationManager.removeToast(root.notifData.id)
                        try {
                            root.notifData.dismiss()
                        } catch(e) {}
                    }
                }
            }
        }

        // Summary / Title
        Text {
            width: parent.width
            visible: text.length > 0
            text: root.parsedContent.summary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            color: Theme.on_surface
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }

        // Body
        Text {
            width: parent.width
            visible: text.length > 0
            text: root.parsedContent.body
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.on_surface_variant
            wrapMode: Text.Wrap
            textFormat: Text.StyledText
            maximumLineCount: 5
            elide: Text.ElideRight
        }

        // Image Preview (if present)
        Image {
            width: parent.width
            height: (!root.isWhatsApp && status === Image.Ready) ? 120 : 0
            visible: !root.isWhatsApp && status === Image.Ready
            source: (!root.isWhatsApp && root.notifData && root.notifData.image) || ""
            fillMode: Image.PreserveAspectCrop
            mipmap: true
            asynchronous: true
        }

        // Action Buttons Row
        Row {
            width: parent.width
            spacing: 6
            visible: root.notifData.actions && root.notifData.actions.length > 0

            Repeater {
                model: root.notifData.actions
                delegate: Rectangle {
                    required property var modelData
                    height: 26
                    radius: 8
                    implicitWidth: actionLabel.implicitWidth + 16
                    color: btnMouse.containsMouse ? Theme.primary : Theme.surface_container
                    border.color: Theme.outline_variant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData.text || modelData.identifier
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: btnMouse.containsMouse ? Theme.on_primary : Theme.on_surface
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            try {
                                modelData.invoke()
                            } catch(e) {}
                            NotificationManager.removeToast(root.notifData.id)
                        }
                    }
                }
            }
        }
    }
}
