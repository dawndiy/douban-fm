import QtQuick 2.4
import Ubuntu.Components 1.3
import "../components"

Page {

    property alias title: header.text

    head {
        contents: DoubanHeader {
            id: header
            text: i18n.tr("Channels")
        }
    }

    ChannelList {
        id: channelList
        anchors {
            bottomMargin: musicToolbar.visible ? musicToolbar.height : 0
            fill: parent
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