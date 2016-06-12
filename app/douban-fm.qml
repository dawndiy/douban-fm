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
import QtSensors 5.0
import UserMetrics 0.1
import Ubuntu.Components 1.3
import Ubuntu.Connectivity 1.0
import "js"
import "components"
import "ui"
import Ubuntu.PerformanceMetrics 0.1


MainView {

    id: root

    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "douban-fm.ubuntu-dawndiy"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true

    width: units.gu(50)
    height: units.gu(75)

    property var offlineMusicList

    Component.onCompleted: {
        pageStack.push(tabs)
        console.debug("[DoubanUser]", isLoginDouban());
        console.debug("[WeiboUser]", isLoginWeibo());
        offlineMusicList = storage.getMusicList()
        start();
    }

    /**
     * Show a notification
     */
    function notification(text, duration) {
        var noti = Qt.createComponent(Qt.resolvedUrl("components/SnackBar.qml"))
        noti.createObject(root, {text: text, duration: duration})
    }

    /**
     * Networking status
     */
    function networkingStatus() {
        console.log(NetworkingStatus.online, IsDesktop)
        return NetworkingStatus.online || IsDesktop;
        // return false
    }

    /**
     * Check if login Douban
     */
    function isLoginDouban() {
        if (storage.getDoubanUser()) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Check if login Sina Weibo
     */
    function isLoginWeibo() {
        if (storage.getWeiboUser()) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * sync music
     *
     * channel_id: maybe "-3", like channel
     * count: 20 TODO: set count
     */
    function syncMusic(channel_id, count) {
        var offline_music_count = 20 - DoubanMusic.syncCount();
        if (offline_music_count > 0) {
            notification(i18n.tr("Start Sync songs..."))
            DoubanMusic.syncMusic(channel_id, offline_music_count);
        }
    }

    /**
     * Start
     */
    function start() {
        console.log("DoubanFM start")

        // check networking
        var is_online = networkingStatus();
        if (!is_online) {
            notification(i18n.tr("No Network!"))
            if (DoubanMusic.syncCount() > 0) {
                notification(i18n.tr("Play offline music now..."), 3)
            }
        }

        // Check whether the user authorization expired
        if (isLoginDouban()) {
            var user = storage.getDoubanUser();
            var expire = Number(user.expires);
            var now = +new Date() / 1000;
            if (now > expire) {
                notification(i18n.tr("User authorization expired, please login again."), 10)
                storage.clearDoubanUser();
                return;
            }
            DoubanMusic.setDBCL2(user.dbcl2);
            if (storage.getConfig("sync") == "true" && is_online) {
                syncMusic("-3")
            }
        }
        if (isLoginWeibo()) {
            var user = storage.getWeiboUser();
            var expire = Number(user.expire);
            var updated = Number(user.updated);
            var now = +new Date();
            if (now > expire+updated) {
                notification(i18n.tr("Weibo authorization expired, please login again."), 10)
                storage.clearWeiboUser();
                return;
            }
        }

        player.nextMusic();
    }

    Storage {
        id: storage
    }

    Metric {
        id: playedMetric
        name: "douban-fm-metrics"
        format:  i18n.tr("Douban-FM played <b>%1</b> songs today")
        emptyFormat: i18n.tr("No songs Douban-FM played today")
        domain: root.applicationName
        minimum: 0.0
    }

    Player {
        id: player
        objectName: "player"
    }

    DoubanAPIHandler {
        id: doubanAPIHandler
        objectName: "doubanAPIHandler"
    }

    // SensorGesture
    SensorGesture {
        gestures: [
            "QtSensors.shake"
            // "QtSensors.whip",
            // "QtSensors.twist",
            // "QtSensors.cover",
            // "QtSensors.hover",
            // "QtSensors.turnover",
            // "QtSensors.pickup",
            // "QtSensors.slam",
            // "QtSensors.doubletap"
        ]
        enabled: true
        onDetected: {
            console.debug("[GESTURE]:", gesture)
            if (storage.getConfig("shake") == "true") {
                player.skip();
            }
        }
    }

    Loader {
        id: musicToolbar
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        asynchronous: true
        visible: pageStack.currentPage.showToolbar || pageStack.currentPage.showToolbar === undefined
        source: Qt.resolvedUrl("components/MusicToolbar.qml")
        z: 200  // put on top of everything else
    }

    PageStack {
        id: pageStack

        Tabs {
            id: tabs
            anchors.fill: parent

            property bool showToolbar: (currentPage.showToolbar || currentPage.showToolbar === undefined) ? true : false

            Tab {
                id: doubanTab
                title: i18n.tr("Douban FM")
                page: Loader {
                    property bool showToolbar: false
                    parent: doubanTab
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: Qt.resolvedUrl("ui/DoubanPage.qml")
                }
            }

            Tab {
                id: channelTab
                title: i18n.tr("Channels")
                page: Loader {
                    property bool showToolbar: true
                    parent: channelTab
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: Qt.resolvedUrl("ui/ChannelPage.qml")
                }
            }

            Tab {
                id: settingsTab
                title: i18n.tr("Settings")
                page: Loader {
                    property bool showToolbar: true
                    parent: settingsTab
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: Qt.resolvedUrl("ui/SettingsPage.qml")
                }
            }
        }
    }

    PerformanceOverlay {
        active: false
    }

}
