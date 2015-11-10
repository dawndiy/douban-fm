import QtQuick 2.4
import Ubuntu.Components 1.2
import Ubuntu.Components.Popups 1.0
import QtQuick.LocalStorage 2.0

Dialog {
    id: dialog

    property string captchaId: ""

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

        TextField {
            id: captchaText
            width: parent.width
            placeholderText: i18n.tr("captcha")
        }

        Image {
            id: captchaImage
            width: parent.width
            height: units.gu(4)
            asynchronous: true
            // fillMode: Image.PreserveAspectCrop

            Component.onCompleted: {
                var captcha_data = DoubanUser.getCaptcha();
                if (captcha_data.result == true) {
                    dialog.captchaId = captcha_data.captchaID;
                    captchaImage.source = "data:image/jpeg;base64," + captcha_data.captchaImage;
                }
            }
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
                    var result = DoubanUser.login(email.text, password.text, captchaText.text, dialog.captchaId);
                    // login success
                    if (result.result == true) {
                        var account = result.user;
                        var user = {
                            id: account.id,
                            uid: account.uid,
                            name: account.name,
                            expires: account.expires,
                            dbcl2: account.dbcL2
                        }
                        console.debug("USER: ", user)
                        storage.saveDoubanUser(user);
                        loginDoubanLabel.text = user.name;
                        PopupUtils.close(dialog)
                    } else {
                        // Email or Password error
                        console.debug(result.message, result.result)
                        // loginAlert.text = i18n.tr("Wrong email or password! Please try again.")
                        loginAlert.text = result.message
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

