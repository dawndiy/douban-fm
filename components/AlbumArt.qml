import QtQuick 2.4
import QtGraphicalEffects 1.0
import Ubuntu.Components 1.2

Item {
    id: root

    property alias source: art.source
    property alias pause: pauseItem.visible
    property alias loading: activity.running

    signal clicked()

    CrossFadeImage {
        id: art

        fadeDuration: 500
        fadeStyle: "cross"
        height: parent.height
        width: parent.width
        anchors {
            centerIn: parent
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: {
                Haptics.play()
                root.clicked()
            }
        }
    }

    Item {
        id: pauseItem

        visible: false
        anchors {
            top: art.top
            left: art.left
        }
        width: art.width
        height: art.height
        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#FFFFFFFF" }
                GradientStop { position: 0.5; color: "#00FFFFFF" }
            }
        }
        Icon {
            id: icon
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            width: units.gu(6)
            height: units.gu(6)
            name: "media-playback-start"
        }
    }

    ActivityIndicator {
        id: activity
        running: false
        anchors {
            horizontalCenter: art.horizontalCenter
            verticalCenter: art.verticalCenter
        }
    }
}
