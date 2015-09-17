import QtQuick 2.4
import Ubuntu.Components 1.2
import Ubuntu.Components.Popups 1.0
import QtQuick.LocalStorage 2.0

import "../js/database.js" as Database


Dialog {
    id: dialog
    title: i18n.tr("Log in")
    text: i18n.tr("Log in with Douban account")

    Column {

        spacing: units.gu(2)

        // login result
        Label {
            id: loginAlert
            text: ""
            anchors.horizontalCenter: parent.horizontalCenter
            visible: false
            color: "red"
        }

        TextField {
            id: email
            width: parent.width
            placeholderText: i18n.tr("email")
        }
        TextField {
            id: password
            width: parent.width
            placeholderText: i18n.tr("password")
            echoMode: TextInput.Password
        }

        Row {
            width: parent.width
            spacing: units.gu(1)
            Button {
                text: i18n.tr("login")
                width: parent.width / 2
                color: UbuntuColors.green
                onClicked: {
                    console.debug("login douban");
                    loginAlert.visible = false;
                    loginAlert.text = "";
                    var result = DoubanUser.login(email.text, password.text);
                    if (result.result == 0) {
                        var user = {
                            user_id: result.id,
                            token: result.token,
                            expire: result.expire,
                            user_name: result.name,
                            email: result.email
                        }
                        Database.saveUser(user);
                        loginDoubanLabel.text = user.user_name;
                        PopupUtils.close(dialog)
                    } else {
                        // Email or Password error
                        console.debug(result.err, result.result)
                        loginAlert.text = i18n.tr("Wrong email or password! Please try again.")
                        loginAlert.visible = true
                    }
                }
            }
            Button {
                text: i18n.tr("cancel")
                width: parent.width / 2
                onClicked: PopupUtils.close(dialog)
            }
        }
    }
}

