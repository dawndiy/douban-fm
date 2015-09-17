import QtQuick 2.4
import Ubuntu.Components 1.2

Item {
    id: notification

    property string text: ""
    property int duration: 3
    
    // width: units.gu(20)
    // height: units.gu(5)
    width: label.width + units.gu(2)
    height: label.height + units.gu(3)
    opacity: 0
    z: 9999

    Component.onCompleted: {
        opacity = 0.75
        timerDisplay.start()
    }

    Behavior on opacity { NumberAnimation{} }

    anchors {
        // verticalCenter: parent.verticalCenter
        horizontalCenter: parent.horizontalCenter
        bottom: parent.bottom
        bottomMargin: units.gu(15)
    }

    Timer {
        id: timerDisplay
        interval: notification.duration * 1000
        running: true
        repeat: false
        triggeredOnStart: false
        onTriggered: {
            console.log("Notification end");
            // notification.destroy();
            animaDestroy.start();
        }
    }

    UbuntuShape {
        color: UbuntuColors.darkGrey
        anchors.fill: parent
        Label {
            id: label
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            text: notification.text
            color: "#FFF"
            // width: parent.width - units.gu(2)
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: animaDestroy.start()
    }

    SequentialAnimation {
        id: animaDestroy
        running: false

        ParallelAnimation {

            UbuntuNumberAnimation {
                target: notification
                property: "scale"
                to: 0.3
            }
            UbuntuNumberAnimation {
                target: notification
                property: "opacity"
                to: 0
            }
        }

        ScriptAction { script: notification.destroy() }
    }
}
