import QtQuick 2.4
import Ubuntu.Components 1.2

import "../components"

Page {

    property alias title: header.text
    property alias selectedChannelID: channelList.selectedChannelID
    property alias selectedChannelName: channelList.selectedChannelName
    property var lastChannelID

    head {
        contents: DoubanHeader {
            id: header
            text: ""
        }
    }


    ChannelList {
        id: channelList
        onDelegateClicked: {
            console.log("[频道选择] ", index, selectedChannelName)
            if (!doubanPage.isLoginDouban() && selectedChannelID == "-3") {
                doubanPage.addNotification(channelPage, i18n.tr("Please Login Douban Account First!"))
                return;
            }
            pageStack.pop()
            doubanPage.song_next(selectedChannelID)
        }
    }
}
