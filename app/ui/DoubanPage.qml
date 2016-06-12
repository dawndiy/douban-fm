/*
 * Copyright (C) 2015, 2016  DawnDIY <dawndiy.dev@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtMultimedia 5.0
import QtGraphicalEffects 1.0
import Ubuntu.Components 1.3
import Ubuntu.Connectivity 1.0
import "../components"


Page {
    id: doubanPage

    //property alias title: header.text
    property var currentSong
    property bool currentLike
    //property alias imageUrl: image.source
    //property alias imageUrl: imageLoader.item.source
    property bool showToolbar: false

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

    header: DoubanHeader {
        title: i18n.tr("Douban FM")

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
                    if (!networkingStatus()) {
                        notification(i18n.tr("No Network!"));
                        return
                    }
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
            }
            // ,
            // Action {
            //     iconName: "info"
            //     text: i18n.tr("Test")
            //     onTriggered: {
            //         var text = "Test Text --afasodaidsf\nasdofifj"
            //         var noti = Qt.createComponent(Qt.resolvedUrl("../components/SnackBar.qml"))
            //         noti.createObject(root, {text: text, duration: duration})
            //     }
            // }
        ]
    }

    // Channel Name
    Text {
        id: channelName
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: doubanPage.header.bottom
            topMargin: units.gu(2)
        }
        text: networkingStatus() ? DoubanChannels.channelByID(Number(player.currentMetaChannelID)).name : i18n.tr("Offline")
        color: "grey"
    }

    // Album Art
    Loader {
        id: imageLoader
        asynchronous: true
        anchors {
            top: doubanPage.header.bottom
            topMargin: units.gu(6)
            left: parent.left
            leftMargin: units.gu(5)
            right: parent.right
            rightMargin: units.gu(5)
            bottom: parent.bottom
            bottomMargin: units.gu(28)
        }
        sourceComponent: Component {

            AlbumArt {
                source: player.currentMetaArt != "" ? Qt.resolvedUrl(player.currentMetaArt) : Qt.resolvedUrl("../images/logo.png")
                // loading: player.status == MediaPlayer.Buffered || player.status == MediaPlayer.Loaded ? false : true;
                loading: player.loading ? true : false
                // pause: player.isPlaying ? false : true;
                pause: player.playbackState === MediaPlayer.PausedState ? true : false
                onClicked: {
                    if (player.currentMetaTitle) {
                        pause = pause ? false : true;
                        if (!pause) {
                            player.play();
                        } else {
                            player.pause();
                        }
                    }
                }

                Connections {
                    target: player
                    onIsPlayingChanged: {
                        pause = !player.isPlaying
                    }
                }
            }
        }
    }

    // Artist Name
    Text {
        id: artist
        text: player.currentMetaArtist

        anchors {
            //top: image.bottom
            top: imageLoader.bottom
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
                return player.currentMetaLike ? UbuntuColors.red : "#4a4a4a"
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
            color: player.playbackState == MediaPlayer.PausedState ? "#CCCCCC" : "#4a4a4a"
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
            color: player.playbackState == MediaPlayer.PausedState ? "#CCCCCC" : "#4a4a4a"
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
