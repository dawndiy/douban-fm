import QtQuick 2.4
import Ubuntu.Components 1.3
import "../components"

Page {
    id: sharePage

    property bool showToolbar: false

    /**
     * Post weibo to Share current music
     */
    function postWeibo(weibo_status) {
        console.debug("[Func postWeibo]", player.currentMusic.title)

        var user = storage.getWeiboUser();
        if (!user) {
            return;
        }
        console.log("TOKEN", user.access_token)

        if (!player.currentMusic.title) {
            console.log("No songs!!")
            return;
        }

        var weiboStatus = textArea.text;
        var picUrl = player.currentMetaArt;

        // Do post status
        Weibo.upload(user.access_token, weiboStatus, picUrl);
        notification(i18n.tr("Sharing success!"))
        pageStack.pop();
    }

    // Weibo status
    function weiboContent(curSong) {
        var song_title = curSong.title;
        var song_artist = curSong.artist;
        var song_url = "http://douban.fm/?start=" + curSong.sid + "g" + curSong.ssid + "g   ";
        var str = "分享 " + song_artist + " 的单曲《" + song_title + "》 " + song_url;
        return str;
    }

    header: DoubanHeader {
        title: i18n.tr("Share to Sina Weibo")

        trailingActionBar.actions: [
            Action {
                iconName: "ok"
                text: i18n.tr("ok")
                onTriggered: {
                    console.debug("[Action: Post Weibo]");
                    postWeibo(textArea.text);
                }
            }
        ]
    }

    Flickable {
        id: flickable

        anchors {
            top: sharePage.header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        contentHeight: column.height
        contentWidth: parent.width

        Column {
            id: column
            spacing: units.gu(2)

            anchors {
                top: parent.top
                topMargin: units.gu(2)
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
            }

            TextArea {
                id: textArea
                width: parent.width
                text: player.currentMusic ? weiboContent(player.currentMusic) : ""
            }

            Image {
                id: image
                source: player.currentMusic ? player.currentMetaArt : ""
                fillMode: Image.PreserveAspectFit
                height: parent.width
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }
        }
    }
}
