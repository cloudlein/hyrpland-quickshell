import QtQuick
import ".."

Rectangle {
    id: root

    property alias text: label.text
    property alias icon: iconLabel.text
    property alias textColor: label.color
    property alias font: label.font
    property alias spacing: contentRow.spacing
    property bool active: false
    property string tooltipText: ""
    signal clicked()
    signal rightClicked()
    signal scrollUp()
    signal scrollDown()

    height: 28
    radius: 12
    color: active ? Theme.primary : Theme.surface_container

    implicitWidth: contentRow.implicitWidth + 18

    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: iconLabel
            visible: text.length > 0
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            color: root.active ? Theme.on_primary : Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: label
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
            color: root.active ? Theme.on_primary : Theme.on_surface
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) root.clicked()
            else if (mouse.button === Qt.RightButton) root.rightClicked()
        }

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) root.scrollUp()
            else if (wheel.angleDelta.y < 0) root.scrollDown()
        }
    }
}
