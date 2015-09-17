import QtQuick 2.4
import Ubuntu.Components 1.2
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
        anchors.fill: parent
        selectedIndex: player.currentMetaChannelIndex

        onClicked: {
            console.log("channel click", index)

            if (index == 1 && !isLoginDouban()) {
                notification("Please login Douban account!");
                return;
            }

            player.currentMetaChannelIndex = index;
            player.currentMetaChannelID = DoubanChannels.channel(index).id;
            pageStack.pop();
        }
    }
}
