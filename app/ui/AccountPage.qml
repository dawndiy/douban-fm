import QtQuick 2.4
import Ubuntu.Components 1.3
import "../components"

Page {
    id: accountPage

    property bool showToolbar: false
    property string vCodeId: ""

    function getVCode() {
        DoubanUser.getVerificationCode()
        activity.running = true
    }

    header: DoubanHeader {
        title: i18n.tr("Login Douban")
    }

    Component.onCompleted: {
        getVCode()
    }

    Connections {
        target: doubanAPIHandler
        onCaptchaImageLoaded: {
            vCodeId = captcha_id
            imageCode.source = "data:image/jpeg;base64," + captcha_data
            activity.running = false
        }
    }

    Connections {
        target: doubanAPIHandler
        onLoginCompleted: {
            console.log("----", result.result)
            if (result.result == true) {
                var account = result.user;
                var user = {
                    id: account.id,
                    uid: account.uid,
                    name: account.name,
                    expires: account.expires,
                    dbcl2: account.dbcL2
                }
                console.debug("USER: ", user.name)
                storage.saveDoubanUser(user);
                // TODO: notification
                pageStack.pop()
            } else {
                loginAlert.text = result.message
                loginAlert.visible = true
            }
        }
    }

    Flickable {
        id: flickable
        anchors {
            top: accountPage.header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        contentHeight: layout.height

        Column {
            id: layout
            spacing: units.gu(2)
            anchors {
                top: parent.top
                topMargin: units.gu(4)
                left: parent.left
                right: parent.right
            }

            TextField {
                id: textUser
                placeholderText: i18n.tr("Username/E-Mail")
                anchors {
                    left: parent.left
                    leftMargin: units.gu(4)
                    right: parent.right
                    rightMargin: units.gu(4)
                }
            }

            TextField {
                id: textPassword
                placeholderText: i18n.tr("Password")
                echoMode: TextInput.Password
                anchors {
                    left: parent.left
                    leftMargin: units.gu(4)
                    right: parent.right
                    rightMargin: units.gu(4)
                }
            }

            Image {
                id: imageCode
                width: textCode.width
                height: textCode.height
                anchors.horizontalCenter: parent.horizontalCenter
                ActivityIndicator {
                    id: activity
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Haptics.play();
                        getVCode()
                    }
                }
            }

            TextField {
                id: textCode
                placeholderText: i18n.tr("Verification Code")
                anchors {
                    left: parent.left
                    leftMargin: units.gu(4)
                    right: parent.right
                    rightMargin: units.gu(4)
                }
            }

            Button {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(4)
                    right: parent.right
                    rightMargin: units.gu(4)
                }
                text: i18n.tr("Log in")
                onClicked: {
                    loginAlert.text = ""
                    loginAlert.visible = false
                    DoubanUser.login(textUser.text, textPassword.text, textCode.text, vCodeId)
                }
            }

            Label {
                id: loginAlert
                text: ""
                anchors.horizontalCenter: parent.horizontalCenter
                visible: false
                color: "red"
            }

        }
    }

}
