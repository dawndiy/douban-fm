import QtQuick 2.4
import Ubuntu.Components 1.2
import QtQuick.LocalStorage 2.0

import "../components"
import "../js/weibo.js" as WeiboAPI
import "../js/database.js" as Database

Page {

    property alias title: header.text
    property alias imageUrl: image.source

    head {
        contents: DoubanHeader {
            id: header
            text: ""
            source: "../images/weibo_64x64.png"
        }
        actions: [
            // 信息
            Action {
                iconName: "ok"
                text: i18n.tr("ok")
                onTriggered: {
                    console.log("ok")
                    postWeibo(textArea.text);
                }
            }
        ]
    }

    Item {

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
            text: doubanPage.currentSong ? weiboContent(doubanPage.currentSong) : ""
        }

        Image {
            id: image
            source: doubanPage.currentSong ? doubanPage.currentSong.picture : ""
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


    // =============================================================
    // Javascript
    // =============================================================
    
    function postWeibo(weibo_status) {

        var auth = Database.getWeiboAuth();
        if (!auth) {
            return
        }
        console.log("TOKEN", auth.access_token)
        console.log(doubanPage.currentSong)

        if (!doubanPage.currentSong) {
            console.log("No songs!!")
            return
        }

        var weibo_status = textArea.text;
        var pic_url = doubanPage.currentSong.picture;

        WeiboAPI.statuses_upload(auth.access_token, weibo_status, pic_url, function() {
            pageStack.pop();
        });
    }

    function weiboContent(curSong) {
        var song_title = curSong.title;
        var song_artist = curSong.artist;
        var song_url = "http://douban.fm/?start=" + curSong.sid + "g" + curSong.ssid + "g   ";
        var str = "分享 " + song_artist + " 的单曲《" + song_title + "》 " + song_url;
        // console.log(str);
        return str;
    }

    // =============================================================

}
