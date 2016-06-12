import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3
import Ubuntu.Components.Popups 1.0
import "../components"


Page {

    id: settingsPage

    header: DoubanHeader {

        title: i18n.tr("Settings")

        leadingActionBar.actions: [
            Action {
                text: i18n.tr("Douban FM")
                onTriggered: {
                    tabs.selectedTabIndex = 0
                }
            },
            Action {
                text: i18n.tr("Channels")
                onTriggered: {
                    tabs.selectedTabIndex = 1
                }
            },
            Action {
                text: i18n.tr("Settings")
                onTriggered: {
                    tabs.selectedTabIndex = 2
                }
            }
        ]

        trailingActionBar.actions: [
            Action {
                iconName: "info"
                text: i18n.tr("Info")
                onTriggered: {
                    // PopupUtils.open(Qt.resolvedUrl("../components/AboutDialog.qml"))
                    pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                }
            }
        ]
    }

    onVisibleChanged: {
        if (visible) {
            loginWeiboLabel.text = isLoginWeibo() ? storage.getWeiboUser().screen_name : i18n.tr("Login Sina Weibo")
            loginDoubanLabel.text = isLoginDouban()? storage.getDoubanUser().name : i18n.tr("Login Douban FM")
        }
    }

    Component {
        id: clearOfflineDialog
        Dialog {
            id: dialog
            title: i18n.tr("Clear")
            text: i18n.tr("Clear all offline music ?")

            Row {
                width: parent.width
                spacing: units.gu(1)
                Button {
                    text: i18n.tr("confirm")
                    width: parent.width / 2
                    color: UbuntuColors.orange
                    onClicked: {
                        DoubanMusic.clearSync();
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

    Component {
        id: logoutDoubanDialog
        LogoutDialog{
            text: i18n.tr("Logout Douban Account?")
            onConfirm: {
                storage.clearDoubanUser();
                DoubanUser.logout();
                loginDoubanLabel.text = i18n.tr("Login Douban FM");
            }
        }
    }

    Component {
        id: logoutWeiboDialog
        LogoutDialog{
            text: i18n.tr("Logout Weibo Account?")
            onConfirm: {
                storage.clearWeiboUser();
                loginWeiboLabel.text = i18n.tr("Login Sina Weibo");
            }
        }
    }

    Flickable {
        id: flickable

        anchors {
            top: settingsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentHeight: settingsColumn.height
        contentWidth: parent.width

        Column { 
            id: settingsColumn

            anchors {
                // top: parent.top
                left: parent.left
                right: parent.right
            }

            Header {
                text: i18n.tr("Account")
            }

            // Douban FM Account
            ListItem {
                Image {
                    id: doubanIcon
                    source: Qt.resolvedUrl("../images/logo.png")
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
                    anchors {
                        left: doubanIcon.right
                        leftMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    text: isLoginDouban()? storage.getDoubanUser().name : i18n.tr("Login Douban FM")
                }
                onClicked: {
                    if (!isLoginDouban()) {
                        if (!networkingStatus()) {
                            notification(i18n.tr("No network!"));
                            return;
                        }
                        pageStack.push(Qt.resolvedUrl("AccountPage.qml"))
                    } else {
                        PopupUtils.open(logoutDoubanDialog);
                    }
                }
            }

            // Weibo Account
            ListItem {
                Image {
                    id: weiboIcon
                    source: Qt.resolvedUrl("../images/weibo_64x64.png")
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
                    text: isLoginWeibo() ? storage.getWeiboUser().screen_name : i18n.tr("Login Sina Weibo")
                    anchors {
                        left: weiboIcon.right
                        leftMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                }
                onClicked: {
                    if (!isLoginWeibo()) {
                        if (!networkingStatus()) {
                            notification(i18n.tr("No network!"));
                            return;
                        }
                        // pageStack.push(weiboLoginPage);
                        pageStack.push(Qt.resolvedUrl("WeiboLoginPage.qml"))
                    } else {
                        PopupUtils.open(logoutWeiboDialog);
                    }
                }
            }

            Header {
                text: i18n.tr("Settings")
            }

            // sync switch
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
                    checked: storage.getConfig("sync") == "true" ? true : false
                    onTriggered: {
                        if (!isLoginDouban()) {
                            notification(i18n.tr("Please login douban account first!"))
                            checked = false
                            storage.setConfig("sync", String(checked))
                            return;
                        }
                        if (checked && networkingStatus()) {
                            var user = storage.getDoubanUser();
                            syncMusic("-3")
                        }
                        storage.setConfig("sync", String(checked))
                    }
                }
            }
            
            // Shake
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
                    checked: storage.getConfig("shake") == "true" ? true : false
                    onTriggered: {
                        console.debug("[Action: shake switch]", checked);
                        storage.setConfig("shake", String(checked))
                    }
                }
            }

            // Clear offline music
            ListItem {
                Label {
                    text: i18n.tr("Clear offline music")
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                }
                Label {
                    id: sync_count
                    text: DoubanMusic.syncCount()
                    anchors {
                        right: parent.right
                        rightMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                }
                onClicked: {
                    console.debug("[Action: Clear Offline music]");
                    PopupUtils.open(clearOfflineDialog);
                }
            }
        }
    }
}

