import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: notification

    property string text: ""
    property int duration: 3

    width: units.gu(20)
    height: label.height + units.gu(2)
    opacity: 0.75
    z: 9999

    Component.onCompleted: {
        notification.anchors.bottomMargin = 0
        timer.start()
    }

    anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
        bottomMargin: -label.height - units.gu(2)

        Behavior on bottomMargin {
            NumberAnimation { duration: 200 }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        Label {
            id: label
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            text: notification.text
            color: "white"
        }
    }

    Timer {
        id: timer
        interval: notification.duration * 1000
        running: true
        repeat: false
        triggeredOnStart: false
        onTriggered: {
            animaDestroy.start()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: animaDestroy.start()
    }

    SequentialAnimation {
        id: animaDestroy

        UbuntuNumberAnimation {
            target: notification.anchors
            property: "bottomMargin"
            to: -label.height-units.gu(2)
        }

        ScriptAction { script: notification.destroy() }
    }
}
