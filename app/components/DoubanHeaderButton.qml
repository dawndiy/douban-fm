import QtQuick 2.4
import Ubuntu.Components 1.3

AbstractButton {
    width: units.gu(4)
    height: parent ? parent.height : undefined
    action: modelData

    Rectangle {
        id: background
        color: parent.pressed ? "#fef6db" : "transparent"
        anchors.fill: parent
    }

    Icon {
        id: icon
        anchors.centerIn: parent
        width: units.gu(2)
        height: width
        source: action.iconSource
        name: action.iconName
        color: "#6bbd7a"
        opacity: parent.enabled ? 1.0 : 0.4
    }
}

