import QtQuick 2.4
import Ubuntu.Components 1.3
import "../components"

Page {
    id: channelPage

    header: DoubanHeader {
        title: i18n.tr("Channels")

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
    }

    ChannelList {
        id: channelList
        anchors {
            bottomMargin: musicToolbar.visible ? musicToolbar.height : 0
            top: channelPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        selectedIndex: player.currentMetaChannelIndex

        onClicked: {
            console.debug("[Action: Channel]", index)

            if (index == 1 && !isLoginDouban()) {
                notification("Please login Douban account!");
                return;
            }

            player.currentMetaChannelIndex = index;
            player.currentMetaChannelID = DoubanChannels.channel(index).id;
            player.playOffline = false;
            //pageStack.pop();
        }
    }
}
