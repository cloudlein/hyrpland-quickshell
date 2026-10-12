import QtQuick
import Quickshell
import ".."
import "../components"

Pill {
    id: root

    icon: NotificationManager.dnd ? "󰂛" : "󰂚"
    text: NotificationManager.dnd ? "DND" : (NotificationManager.unreadCount > 0 ? "" + NotificationManager.unreadCount : "")
    active: NotificationManager.controlCenterOpen || NotificationManager.dnd

    tooltipText: NotificationManager.dnd 
        ? "Do Not Disturb (Right-click to toggle)" 
        : (NotificationManager.unreadCount > 0 
            ? `${NotificationManager.unreadCount} Notifications` 
            : "Notifications")

    onClicked: NotificationManager.toggleControlCenter()
    onRightClicked: NotificationManager.toggleDnd()
}
