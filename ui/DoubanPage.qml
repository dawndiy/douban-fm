import QtQuick 2.4
import QtMultimedia 5.0
import QtGraphicalEffects 1.0
import Ubuntu.Components 1.2
import Ubuntu.Connectivity 1.0
import "../components"


Page {
    id: doubanPage

    property alias title: header.text
    property var currentSong
    property bool currentLike
    property alias imageUrl: image.source

    /**
     * Like this music
     */
    function musicLike() {
        console.debug("[Func: musicLike]", !player.currentMetaLike, player.currentMusic.sid, player.currentMusic.title);
        // if (!isLoginDouban()) {
        //     notification(i18n.tr("Please login Douban Account first!"))
        //     return;
        // }
        // check current music
        if (player.currentMetaLike == true) {
            player.unrateMusic();
        } else {
            player.rateMusic();
        }
    }

    /**
     * Ban this music
     */
    function musicBan() {
        console.debug("[Func: musicBan]", player.currentMusic.sid, player.currentMusic.title);
        // if (!isLoginDouban()) {
        //     notification(i18n.tr("Please login Douban Account first!"))
        //     return;
        // }
        player.banMusic();
    }

    /**
     * Return countdown
     */
    function musicTime(duration, position) {
        var min = Math.floor((duration - position) / 60000);
        var sec = Math.floor((duration - position) % 60000 / 1000);
        if (sec < 0 ) {
            sec = 0;
        }
        if (min < 0 ) {
            min = 0;
        }
        if (sec < 10) {
            sec = "0" + sec;
        }
        var text = min + ":" + sec;
        return text
    }

    head {
        contents: DoubanHeader {
            id: header
            text: i18n.tr("Douban FM")
        }

        actions: [
            // Channel List
            Action {
                iconName: "view-list-symbolic"
                text: i18n.tr("Channels")
                onTriggered: {
                    if (!networkingStatus()) {
                        notification(i18n.tr("No network!"));
                        return;
                    }
                    pageStack.push(Qt.resolvedUrl("ChannelPage.qml"));
                }
            },
            // Share
            Action {
                iconName: "share"
                text: i18n.tr("Share")
                onTriggered: {
                    if (!networkingStatus()) {
                        notification(i18n.tr("No network!"));
                        return;
                    }
                    if (!isLoginWeibo()) {
                        notification(i18n.tr("Please login weibo account first!"));
                        return;
                    }
                    if (!player.currentMusic.title) {
                        notification(i18n.tr("No Songs to share."));
                        return;
                    }
                    pageStack.push(Qt.resolvedUrl("SharePage.qml"));
                }
            },
            // Settings
            Action {
                iconName: "settings"
                text: i18n.tr("Settings")
                onTriggered: {
                    pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                }
            }
        ]
    }

    // Channel Name
    Text {
        id: channelName
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: units.gu(2)
        }
        text: networkingStatus() ? DoubanChannels.channelByID(Number(player.currentMetaChannelID)).name : i18n.tr("Offline")
        color: "grey"
    }


    // Album Art
    AlbumArt {
        id: image
        source: player.currentMetaArt != "" ? Qt.resolvedUrl(player.currentMetaArt) : Qt.resolvedUrl("../images/logo.png")
        loading: player.status == MediaPlayer.Buffered || player.status == MediaPlayer.Loaded ? false : true;
        pause: player.isPlaying ? false : true;
        anchors {
            top: parent.top
            topMargin: units.gu(6)
            left: parent.left
            leftMargin: units.gu(5)
            right: parent.right
            rightMargin: units.gu(5)
            bottom: parent.bottom
            bottomMargin: units.gu(28)
        }
        onClicked: {
            if (player.currentMetaTitle) {
                image.pause = image.pause ? false : true;
                if (!image.pause) {
                    player.play();
                } else {
                    player.pause();
                }
            }
        }
    }

    // Artist Name
    Text {
        id: artist
        text: player.currentMetaArtist

        anchors {
            top: image.bottom
            topMargin: units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
    }

    // Album Name & Year
    Text {
        id: album
        text: player.currentMetaAlbum
        font.pixelSize: FontUtils.sizeToPixels("x-small")

        anchors {
            top: artist.bottom
            topMargin: units.gu(0.5)
            horizontalCenter: parent.horizontalCenter
        }
    }

    // Music Name
    Text {
        id: title
        text: player.currentMetaTitle
        font.pixelSize: FontUtils.sizeToPixels("large")

        anchors {
            top: album.bottom
            topMargin: units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
    }

    // Music duration
    Text {
        id: duration
        text: musicTime(player.duration, player.position);

        anchors {
            top: title.bottom
            topMargin: units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
    }

    // Operation Buttons
    Row {
        id: row
        spacing: units.gu(7)
        anchors {
            bottom: parent.bottom
            bottomMargin: units.gu(5)
            horizontalCenter: parent.horizontalCenter
        }

        // Like this music
        Icon {
            id: likeImage
            width: units.gu(6)
            height: units.gu(6)
            name: "like"
            color: {
                if (player.playbackState == MediaPlayer.PausedState) {
                    return "#CCCCCC"
                }
                return player.currentMetaLike ? UbuntuColors.red : UbuntuColors.lightGrey
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!networkingStatus()) {
                        notification(i18n.tr("No Network!"));
                        return;
                    }
                    if (player.playbackState != MediaPlayer.PausedState) {
                        console.debug("[Action: Like]");
                        Haptics.play()
                        musicLike();
                    }
                }
            }
        }

        // Do not like this music
        Icon {
            id: deleteImage
            width: units.gu(6)
            height: units.gu(6)
            name: "edit-delete"
            color: player.playbackState == MediaPlayer.PausedState ? "#CCCCCC" : UbuntuColors.lightGrey
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!networkingStatus()) {
                        notification(i18n.tr("No Network!"));
                        return;
                    }
                    if (player.playbackState != MediaPlayer.PausedState) {
                        console.debug("[Action: Ban]");
                        Haptics.play();
                        musicBan();
                    }
                }
            }
        }

        // Next music
        Icon {
            id: nextImage
            width: units.gu(6)
            height: units.gu(6)
            name: "media-skip-forward"
            color: player.playbackState == MediaPlayer.PausedState ? "#CCCCCC" : UbuntuColors.lightGrey
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (player.playbackState != MediaPlayer.PausedState) {
                        console.debug("[Action: Next]");
                        Haptics.play();
                        player.skip();
                    }
                }
            }
        }
    }
}
