import QtQuick 2.4
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0

Dialog {
    id: dialog

    title: i18n.tr("About Douban FM")

    Item {
        width: units.gu(20)
        height: units.gu(8)
        Image {

            property var clickTime: 0
            property int clickCount: 0

            id: appIcon
            anchors.horizontalCenter: parent.horizontalCenter
            source: "../images/logo.png"
            sourceSize.width: units.gu(10)
            sourceSize.height: units.gu(10)
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var now = new Date();
                    var diff = now.getTime() - appIcon.clickTime;
                    if (diff > 250) {
                        appIcon.clickCount = 0;
                    } else {
                        appIcon.clickCount += 1;
                    }
                    appIcon.clickTime = now.getTime();
                    if (appIcon.clickCount >= 2) {
                        console.log("Easter Eggs")
                        pageStack.push(Qt.resolvedUrl("../ui/EggsPage.qml"))
                        notification(i18n.tr("★★★ Wow! You find this Easter egg!★★★ "), 8)
                        PopupUtils.close(dialog)
                        appIcon.clickCount = 0;
                    }
                }
            }
        }
    }

    Item {
        height: units.gu(2)
    }

    Label {
        text: i18n.tr("Douban FM for Ubuntu Touch")
        anchors {
            left: parent.left
            right: parent.right
        }
        color: "black"
    }

    ListItem.ThinDivider{}

    Label {
        text: i18n.tr("Version: ") + ApplicationVersion
        anchors {
            left: parent.left
            right: parent.right
        }
        color: "black"
    }

    Label {
        text: i18n.tr("Author: DawnDIY")
        anchors {
            left: parent.left
            right: parent.right
        }
        color: "black"
    }

    Label {
        text: i18n.tr("Email: chenglu1990@gmail.com")
        anchors {
            left: parent.left
            right: parent.right
        }
        color: "black"
    }

    Button {
        text: i18n.tr("Close")
        onClicked: PopupUtils.close(dialog)
    }
}
