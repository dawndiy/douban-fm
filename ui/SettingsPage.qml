import QtQuick 2.4
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0
import Ubuntu.Components.Popups 1.0
import QtQuick.LocalStorage 2.0

import "../components"
import "../js/database.js" as Database


Page {

    id: settingsPage

    property alias title: header.text
    property alias loginWeiboLabel: loginWeiboLabel
    property alias loginDoubanLabel: loginDoubanLabel
    property alias settingShakeSwitch: settingShakeSwitch

    head {
        contents: DoubanHeader {
            id: header
            text: ""
        }

        actions: [
            // 信息
            Action {
                iconName: "info"
                text: i18n.tr("Info")
                onTriggered: {
                    console.log("info")
                    PopupUtils.open(dialog)
                }
            }
        ]
    }

    Component {
        id: dialog
        AboutDialog{}
    }

    Component {
        id: loginDialog
        LoginDialog{}
    }

    Component {
        id: logoutDoubanDialog
        LogoutDialog{
            target: "douban"
        }
    }

    Component {
        id: logoutWeiboDialog
        LogoutDialog{
            target: "weibo"
            text: "Logout Weibo Account?"
        }
    }
    Component {
        id: delOfflineDialog
        Dialog {
            id: dialog
            title: i18n.tr("Delete")
            text: i18n.tr("Delete all offline music ?")

            Row {
                width: parent.width
                spacing: units.gu(1)
                Button {
                    text: i18n.tr("confirm")
                    width: parent.width / 2
                    color: UbuntuColors.orange
                    onClicked: {
                        song.clearSync();
                        sync_count.text = 0;
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
    }

    // Settings
    Column {
        anchors.fill: parent

        Header {
            text: i18n.tr("Account")
        }

        // Douban FM Account
        ListItem {
            Image {
                id: doubanIcon
                source: "../images/logo.png"
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                height: units.gu(4)
                width: units.gu(4)
            }
            Label {
                id: loginDoubanLabel
                text: isLoginDouban()? Database.getUser().user_name : i18n.tr("Log in Douban FM")
                anchors {
                    left: doubanIcon.right
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
            }
            onClicked: {
                if (!isLoginDouban()) {
                    if (!doubanPage.check_network()) {
                        doubanPage.addNotification(settingsPage, i18n.tr("No network!"))
                        return;
                    }
                    PopupUtils.open(loginDialog)
                } else {
                    PopupUtils.open(logoutDoubanDialog)
                }
            }
        }
 
        // Weibo Account
        ListItem {
            Image {
                id: weiboIcon
                source: "../images/weibo_64x64.png"
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                height: units.gu(4)
                width: units.gu(4)
            }
            Label {
                id: loginWeiboLabel
                text: isLoginWeibo() ? Database.getWeiboAuth().screen_name : i18n.tr("Log in Sina Weibo")
                anchors {
                    left: weiboIcon.right
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
            }
            onClicked: {
                if (!isLoginWeibo()) {
                    if (!doubanPage.check_network()) {
                        doubanPage.addNotification(settingsPage, i18n.tr("No network!"))
                        return;
                    }
                    weiboLoginPage.url = "https://api.weibo.com/oauth2/authorize?client_id=" + weibo.key + "&response_type=code&redirect_uri=https://api.weibo.com/oauth2/default.html&display=mobile"
                    pageStack.push(weiboLoginPage)
                } else {
                    PopupUtils.open(logoutWeiboDialog)
                }
            }
        }

        Header {
            text: i18n.tr("Settings")
        }

        // 离线开关
        ListItem {
            Label {
                text: i18n.tr("Allow sync offline music")
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
            }
            Switch {
                anchors {
                    right: parent.right
                    rightMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                checked: Database.getConfig("sync") == "true" ? true : false
                onTriggered: {
                    if (!isLoginDouban()) {
                        doubanPage.addNotification(settingsPage, i18n.tr("Please login douban account first!"))
                        checked = false
                        return;
                    }
                    if (checked && doubanPage.check_network()) {
                        doubanPage.addNotification(settingsPage, i18n.tr("Start Sync songs..."))
                        doubanPage.syncOffMusic();
                    }
                    Database.setConfig("sync", String(checked))
                }
            }
        }
        
        // 摇一摇
        ListItem {
            Label {
                text: i18n.tr("Shake to play next")
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
            }
            Switch {
                id: settingShakeSwitch
                anchors {
                    right: parent.right
                    rightMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                checked: Database.getConfig("shake") == "true" ? true : false
                onTriggered: {
                    console.log("SWITCH: ", checked);
                    Database.setConfig("shake", String(checked))
                }
            }
        }

        // 清除离线数据
        ListItem {
            Label {
                text: i18n.tr("Delete offline music")
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
            }
            Label {
                id: sync_count
                text: song.syncCount()
                anchors {
                    right: parent.right
                    rightMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
            }
            onClicked: {
                console.log("清理")
                PopupUtils.open(delOfflineDialog)
            }
        }
        /*
        ListItem {
            Label {
                text: i18n.tr("Off timer")
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        ListItem {
            Button {
                text: "Press me"
            }
            onClicked: console.log("clicked on ListItem")
        }
        ListItem {
            leadingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "delete"
                    }
                ]
            }
            onClicked: console.log("clicked on ListItem with leadingActions set")
        }
        ListItem {
            trailingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "edit"
                    }
                ]
            }
            onClicked: console.log("clicked on ListItem with trailingActions set")
        }
        ListItem {
            Label {
                text: "onClicked implemented"
            }
            onClicked: console.log("clicked on ListItem with onClicked implemented")
        }
        ListItem {
            Label {
                text: "onPressAndHold implemented"
            }
            onPressAndHold: console.log("long-pressed on ListItem with onPressAndHold implemented")
        }
        ListItem {
            Label {
                text: "No highlight"
            }
        }
        */
    }

    // =============================================================
    // Javascript
    // =============================================================

    function isLoginDouban() {

        if (Database.getUser()) {
            return true
        } else {
            return false
        }
    }

    function isLoginWeibo() {

        if (Database.getWeiboAuth()) {
            return true
        } else {
            return false
        }
    }

    // =============================================================

}

