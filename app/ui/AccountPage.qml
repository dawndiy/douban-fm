import QtQuick 2.4
import Ubuntu.Components 1.3
import "../components"

Page {

    property alias title: header.text

    function getVerificationCode() {
    }

    head {
        contents: DoubanHeader {
            id: header
            text: i18n.tr("Offline Music")
        }

        actions: [
            // Action {
            //     iconName: "save"
            //     text: i18n.tr("Save")
            // },

            // Action {
            //     iconName: "note"
            //     text: i18n.tr("Note")
            // }
        ]

        // sections {
        //     id: sections
        //     model: [i18n.tr("Account"), i18n.tr("Music")]
        // }
    }

    Loader {
        id: loader
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.visible ? musicToolbar.height : 0
        sourceComponent: {
            return myMusic
            // if (sections.selectedIndex == 0) {
            //     return myAccount
            // } else {
            //     return myMusic
            // }
        }
    }

    Component {
        id: myMusic
        Item {
            anchors.fill: parent

            ListView {
                anchors.fill: parent
                model: offlineMusicList
                delegate: ListItem {

                    Item {
                        anchors.fill: parent

                        Image {
                            id: musicImage
                            height: parent.height
                            width: parent.height
                            anchors {
                                verticalCenter: parent.verticalCenter
                            }
                            source: offlineMusicList[index].picture
                            fillMode: Image.PreserveAspectFit
                        }

                        Column {
                            anchors {
                                left: musicImage.right
                                leftMargin: units.gu(1.5)
                                right: likeIcon.right
                                rightMargin: units.gu(1.5)
                                verticalCenter: parent.verticalCenter
                            }

                            Label {
                                id: musicTitle
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                }
                                //color: "#FFF"
                                elide: Text.ElideRight
                                fontSize: "small"
                                font.weight: Font.DemiBold
                                text: offlineMusicList[index].title
                            }

                            Label {
                                id: musicArtist
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                }
                                //color: "#FFF"
                                elide: Text.ElideRight
                                fontSize: "small"
                                opacity: 0.4
                                text: offlineMusicList[index].artist
                            }
                        }

                        Icon {
                            id: likeIcon
                            anchors {
                                right: parent.right
                                rightMargin: units.gu(2)
                                verticalCenter: parent.verticalCenter
                            }
                            height: parent.height / 3
                            width: height
                            name: "like"
                            opacity: 0.6
                            color: offlineMusicList[index].like == 1 ? "#F00" : "#CCC"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("select " + index)
                                if (player.playOffline == false) {
                                    player.playOffline = true
                                    notification(i18n.tr("Play offline music now..."), 3)
                                }
                                player.playOfflineIndex = index
                                player.nextMusic()
                            }
                        }

                    }

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                onTriggered: {
                                }
                            }
                        ]
                    }

                    trailingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "media-playback-start"
                                onTriggered: {
                                    player.playOffline = true
                                    player.playOfflineIndex = index
                                    player.nextMusic()
                                }
                            },
                            Action {
                                iconName: "share"
                                onTriggered: {
                                }
                            },
                            Action {
                                iconName: "like"
                                onTriggered: {
                                }
                            }
                        ]
                    }

                }
            }
        }
    }

    Component {
        id: myAccount
    Item {
        anchors.fill: parent

        Component.onCompleted: {
            activity.running = true
            doubanAPIHandler.getVerificationCode()
        }

        Connections {
            target: doubanAPIHandler
            onCaptchaImageLoaded: {
                varificationCodeImage.source = "data:image/jpeg;base64," + captcha_data
            }
        }

        Label {
            id: loginLabel
            anchors {
                top: parent.top
                topMargin: units.gu(6)
                horizontalCenter: parent.horizontalCenter
            }
            text: i18n.tr("Login Douban Account")
        }

        Column {
            id: inputs

            anchors {
                top: loginLabel.bottom
                topMargin: units.gu(2)
                left: parent.left
                right: parent.right
                margins: units.gu(4)
            }
            spacing: units.gu(1)


            TextField {
                id: inputUser
                anchors.left: parent.left
                anchors.right: parent.right
                placeholderText: i18n.tr("Username or Email")
            }

            TextField {
                id: inputPassword
                anchors.left: parent.left
                anchors.right: parent.right
                placeholderText: i18n.tr("Password")
            }

            TextField {
                id: inputVarificationCode
                anchors.left: parent.left
                anchors.right: parent.right
                placeholderText: i18n.tr("Varification Code")
            }

            Image {
                id: varificationCodeImage
                anchors.left: parent.left
                anchors.right: parent.right
                height: units.gu(5)
                // fillMode: Image.PreserveAspectFit
                ActivityIndicator {
                    id: activity
                    running: false
                    anchors {
                        horizontalCenter: varificationCodeImage.horizontalCenter
                        verticalCenter: varificationCodeImage.verticalCenter
                    }
                }

                onStatusChanged: {
                    if (varificationCodeImage.status == Image.Ready) {
                        activity.running = false
                    }
                }
            }



            Button {
                id: loginBtn
                width: parent.width
                text: i18n.tr("Login")
                color: UbuntuColors.green
                onClicked: {
                    activity.running = true
                    doubanAPIHandler.getVerificationCode()
                }
            }
        }
    }}



}
