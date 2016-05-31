import QtQuick 2.4
import QtMultimedia 5.0
import Ubuntu.Components 1.3

Rectangle {
    anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }
    opacity: 0.75
    height: units.gu(7.25)
    objectName: "musicToolbarObject"

    Item {
        id: toolbarControls
        anchors.fill: parent

        //Image {
        CrossFadeImage {
            id: playerControlsImage
            fillMode: Image.PreserveAspectFit
            fadeStyle: "cross"
            source: player.currentMetaArt
            height: parent.height
            width: height
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
        }

        ActivityIndicator {
            id: activity
            running: player.loading
            anchors {
                horizontalCenter: playerControlsImage.horizontalCenter
                verticalCenter: playerControlsImage.verticalCenter
            }
        }

        Column {
            anchors {
                left: playerControlsImage.right
                leftMargin: units.gu(1.5)
                right: playerControlsPlayButton.left
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }

            Label {
                id: playerControlsTitle
                anchors {
                    left: parent.left
                    right: parent.right
                }
                //color: "#FFF"
                elide: Text.ElideRight
                fontSize: "small"
                font.weight: Font.DemiBold
                text: player.currentMetaTitle
            }

            Label {
                id: playerControlsArtist
                anchors {
                    left: parent.left
                    right: parent.right
                }
                //color: "#FFF"
                elide: Text.ElideRight
                fontSize: "small"
                opacity: 0.4
                text: player.currentMetaArtist
            }
        }

        Icon {
            id: playerControlsPlayButton
            anchors {
                right: parent.right
                rightMargin: units.gu(3)
                verticalCenter: parent.verticalCenter
            }
            // color: "#FFF"
            height: units.gu(4)
            name: player.playbackState === MediaPlayer.PlayingState ?
                        "media-playback-pause" : "media-playback-start"
            objectName: "playShape"
            width: height
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                Haptics.play()
                tabs.selectedTabIndex = 0
            }
        }

        MouseArea {
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: playerControlsPlayButton.horizontalCenter
            }
            onClicked: {
                Haptics.play()
                player.toggle()
            }
            width: units.gu(8)
        }
    }

    Rectangle {
        id: playerControlsProgressBar
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        //color: styleMusic.common.black
        height: units.gu(0.25)

        Rectangle {
            id: playerControlsProgressBarHint
            anchors {
                left: parent.left
                top: parent.top
            }
            color: UbuntuColors.orange
            height: parent.height
            width: player.duration > 0 ? (player.position / player.duration) * playerControlsProgressBar.width : 0

            Connections {
                target: player
                onPositionChanged: {
                    playerControlsProgressBarHint.width = (player.position / player.duration) * playerControlsProgressBar.width
                }
                onStopped: {
                    playerControlsProgressBarHint.width = 0;
                }
            }
        }
    }

    Rectangle {
        id: toolbarShadow
        anchors {
            bottom: toolbarControls.top
            left: parent.left
            right: parent.right
        }
        height: units.gu(0.6)
        opacity: 0.25
        gradient: Gradient {
            GradientStop {position: 0.0; color: "#FFF"}
            GradientStop {position: 0.9; color: "#000"}
        }
    }
}
