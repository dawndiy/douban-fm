import QtQuick 2.4
import Ubuntu.Components 1.2
import Ubuntu.Components.Popups 1.0
import QtQuick.LocalStorage 2.0

import "../js/database.js" as Database


Dialog {
    id: dialog
    title: i18n.tr("Log out")
    text: i18n.tr("Log out account ?")

    property string target

    Row {
        width: parent.width
        spacing: units.gu(1)
        Button {
            text: i18n.tr("logout")
            width: parent.width / 2
            color: UbuntuColors.orange
            onClicked: {

                if (target == "douban"){
                    Database.clearUser();
                    loginDoubanLabel.text = i18n.tr("Log in Douban FM")
                } else if (target == "weibo") {
                    Database.clearWeiboAuth();
                    loginWeiboLabel.text = i18n.tr("Log in Weibo")
                }
                PopupUtils.close(dialog)
            }
        }
        Button {
            text: i18n.tr("cancel")
            width: parent.width / 2
            onClicked: PopupUtils.close(dialog)
        }
    }
}

