import QtQuick 2.4
import Ubuntu.Components 1.2
import "../components"

Page {

    property alias title: header.text
    property alias imageUrl: image.source

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


    head {
        contents: DoubanHeader {
            id: header
            text: "Share"
            source: Qt.resolvedUrl("../images/weibo_64x64.png")
        }
        actions: [
            // Post
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

    // Flickable {
    //     id: flickable

    //     anchors.fill: parent
    //     contentHeight: content.height
    //     contentWidth: parent.width

        Column {
            id: content

            anchors {
                top: parent.top
                topMargin: units.gu(2)
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
                bottom: parent.bottom
            }

            Label {
                id: shareLabel
                text: i18n.tr("<b>Share to Sina Weibo:</b>")
                font.pixelSize: FontUtils.sizeToPixels("large")
            }

            TextArea {
                id: textArea
                width: parent.width
                anchors {
                    top: shareLabel.bottom
                    topMargin: units.gu(1)
                }
                text: player.currentMusic ? weiboContent(player.currentMusic) : ""
            }

            Image {
                id: image
                source: player.currentMusic ? player.currentMetaArt : ""
                fillMode: Image.PreserveAspectFit
                anchors {
                    top: textArea.bottom
                    topMargin: units.gu(2)
                    left: parent.left
                    leftMargin: units.gu(5)
                    right: parent.right
                    rightMargin: units.gu(5)
                    bottom: parent.bottom
                    bottomMargin: units.gu(5)
                }
            }
        }
    // }
}
