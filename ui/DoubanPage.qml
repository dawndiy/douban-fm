import QtQuick 2.4
import QtSensors 5.0
import QtMultimedia 5.0
import QtGraphicalEffects 1.0
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.2
import Ubuntu.Connectivity 1.0

import "../components"
import "../js/database.js" as Database

Page {

    property alias title: header.text
    property var currentSong
    property bool currentLike
    property alias imageUrl: image.source

    // 主页头部
    head {
        contents: DoubanHeader {
            id: header
            text: ""
        }

        actions: [
            // DEBUG
            // Action {
            //     iconName: "torch-on"
            //     text: i18n.tr("DEBUG")
            //     onTriggered: {
            //         pageStack.push(test)
            //     }
            // },
            // 频道列表
            Action {
                iconName: "view-list-symbolic"
                text: i18n.tr("Channels")
                onTriggered: {
                    if (!check_network()) {
                        addNotification(doubanPage, i18n.tr("No network!"))
                        return;
                    }
                    pageStack.push(channelPage)
                }
            },
            // 分享
            Action {
                iconName: "share"
                text: i18n.tr("Share")
                onTriggered: {
                    if (!check_network()) {
                        addNotification(doubanPage, i18n.tr("No network!"))
                        return;
                    }
                    if (!isLoginWeibo()) {
                        addNotification(doubanPage, i18n.tr("Please login weibo account first!"))
                        return;
                    }
                    pageStack.push(sharePage)
                }
            },
            // 设置
            Action {
                iconName: "settings"
                text: i18n.tr("Settings")
                onTriggered: {
                    pageStack.push(settingsPage)
                }
            }
        ]
    }

    // 传感器手势
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
            console.log(gesture)
            if (settingsPage.settingShakeSwitch.checked) {
                song_next();
            }
        }
    }


    // 频道名称
    Text {
        id: channelName
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: units.gu(2)
        }
        text: check_network() ? channelPage.selectedChannelName : i18n.tr("离线歌曲")
        color: "grey"
    }


    // 歌曲图片
    CrossFadeImage {
        id: image
        source: "../images/logo.png"
        fadeDuration: 500
        fadeStyle: "cross"
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
        MouseArea {
            anchors.fill: parent

            onClicked: {

                Haptics.play()
                console.log("Pause or Play", playMusic.status)
                if (!isLoginDouban() && channelPage.selectedChannelID == "-3") {
                    addNotification(doubanPage, i18n.tr("Please login douban account first \nor change another channel!"));
                    return ;
                }
                
                if (playMusic.status != MediaPlayer.InvalidMedia && playMusic.status != MediaPlayer.NoMedia) {

                    if (playMusic.playbackState == MediaPlayer.PausedState) {
                        song_play()
                        pauseImage.visible = false
                    } else {
                        song_pause()
                        pauseImage.visible = true
                    }
                }
            }
        }
    }

    ActivityIndicator {
        id: activity
        running: false
        anchors {
            horizontalCenter: image.horizontalCenter
            verticalCenter: image.verticalCenter
        }
    }


    // 暂停层
    Item {
        id: pauseImage
        visible: false
        //anchors.fill: image
        anchors {
            top: image.top
            left: image.left
        }
        width: image.width
        height: image.height
        //color: "#000"
        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#FFFFFFFF" }
                GradientStop { position: 0.5; color: "#00FFFFFF" }
            }
        }
        //opacity: 1.0
        Icon {
            id: icon
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            width: units.gu(6)
            height: units.gu(6)
            name: "media-playback-start"
        }
    }


    // 媒体播放器
    MediaPlayer {
        id: playMusic
        source: ""

        // 停止事件
        onStopped: {
            console.log("停止!!!!!", playMusic.status)
            if (playMusic.status == MediaPlayer.EndOfMedia) {
                // 添加用户数据统计
                playedMetric.increment();
                // 歌曲播放完毕
                song_next();
            } else if (playMusic.status == MediaPlayer.InvalidMedia) {
                // 无效歌曲
                song_next();
            }
        }

        // 暂停事件
        onPaused: {
            console.log("暂停了, 状态: ", playMusic.status)
            pauseImage.visible = true
            likeImage.color = "#CCCCCC"
            deleteImage.color = "#CCCCCC"
            nextImage.color = "#CCCCCC"
        }

        // 播放事件
        onPlaying: {
            console.log("播放中, 状态: ", playMusic.status)
            console.log(playMusic.duration)
            pauseImage.visible = false
            likeImage.color = currentLike ? UbuntuColors.red : UbuntuColors.lightGrey
            deleteImage.color = UbuntuColors.lightGrey
            nextImage.color = UbuntuColors.lightGrey
        }

        // 状态改变事件
        onStatusChanged: {
            console.log("状态改变", playMusic.status, playMusic.duration)
            if (playMusic.status == MediaPlayer.Buffered || playMusic.status == MediaPlayer.Loaded) {
                activity.running = false
            }
        }

        // 位置改变事件
        onPositionChanged: {
            if (playMusic.duration != -1) {
                var len_min = Math.floor((playMusic.duration - playMusic.position) / 60000);
                var len_sec = Math.floor((playMusic.duration - playMusic.position) % 60000 / 1000);
                if (len_sec < 0 ) {
                    len_sec = 0;
                }
                if (len_min < 0 ) {
                    len_min = 0;
                }
                if (len_sec < 10) {
                    len_sec = "0" + len_sec;
                }
                duration.text = len_min + ":" + len_sec;
            }
        }
    }

    // 歌曲歌手
    Text {
        id: artist
        text: ""

        anchors {
            top: image.bottom
            topMargin: units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
    }

    // 歌曲歌手
    Text {
        id: album
        text: ""
        font.pixelSize: FontUtils.sizeToPixels("x-small")

        anchors {
            top: artist.bottom
            topMargin: units.gu(0.5)
            horizontalCenter: parent.horizontalCenter
        }
    }

    // 歌曲名称
    Text {
        id: title
        text: ""
        font.pixelSize: FontUtils.sizeToPixels("large")

        anchors {
            top: album.bottom
            topMargin: units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
    }

    // 歌曲时长
    Text {
        id: duration
        text: ""

        anchors {
            top: title.bottom
            topMargin: units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
    }

    // 操作按钮
    Row {
        id: row
        spacing: units.gu(7)
        anchors {
            bottom: parent.bottom
            bottomMargin: units.gu(5)
            horizontalCenter: parent.horizontalCenter
        }

        // 喜欢按钮
        Icon {
            id: likeImage
            width: units.gu(6)
            height: units.gu(6)
            name: "like"
            color: UbuntuColors.lightGrey
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!check_network()) {
                        addNotification(doubanPage, i18n.tr("No network!"), 10)
                        Haptics.play()
                        return;
                    }
                    if (playMusic.playbackState != MediaPlayer.PausedState) {
                        console.log("Like or Unlike")
                        Haptics.play()
                        if (!isLoginDouban()) {
                            addNotification(doubanPage, i18n.tr("Please login Douban Account first!"))
                            return;
                        }
                        if (parent.color == UbuntuColors.red) {
                            song_unlike();
                        } else {
                            song_like();
                        }
                    }
                }
            }
        }

        // 删除按钮
        Icon {
            id: deleteImage
            width: units.gu(6)
            height: units.gu(6)
            name: "edit-delete"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!check_network()) {
                        addNotification(doubanPage, i18n.tr("No network!"), 10)
                        Haptics.play()
                        return;
                    }
                    if (playMusic.playbackState != MediaPlayer.PausedState) {
                        console.log("Del");
                        Haptics.play();
                        if (!isLoginDouban()) {
                            addNotification(doubanPage, i18n.tr("Please login Douban Account first!"))
                            return;
                        }
                        song_delete();
                    }
                }
            }
        }
        // 下一首按钮
        Icon {
            id: nextImage
            width: units.gu(6)
            height: units.gu(6)
            name: "media-skip-forward"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (playMusic.playbackState != MediaPlayer.PausedState) {
                        console.log("Next");
                        Haptics.play();
                        song_next();
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        start();
    }

    // =============================================================
    // Javascript Functions
    // =============================================================

    /**
     * 下一首歌曲
     */
    function song_next(channel_id) {

        // 开启 loading
        activity.running = true

        // 频道
        channel_id = channel_id || String(channelPage.selectedChannelID);
        channel_id = String(channel_id);

        var is_login = isLoginDouban();
        var is_online = check_network();
        var s;  // 下一首歌曲

        // is_online = false

        if (is_online) {
            // 网络连接
            if (is_login) {
                var user = Database.getUser();
                s = song.nextWithUser(channel_id, user.user_id, user.expire, user.token);
            } else {
                if (channel_id == "-3") {
                    activity.running = false
                    addNotification(doubanPage, i18n.tr("Please login douban account first \nor change another channel!"));
                    return;
                }
                s = song.next(channel_id);
            }
        } else {
            // 无网络
            s = song.nextOffMusic();

            image.source = "";
            playMusic.source = "";
        }

        console.log(s)

        if (!s.title) {
            // 没有歌曲
            addNotification(doubanPage, i18n.tr("No more songs, please check network or retry"), 20);
            return ;
        }

        currentSong = s;

        console.log("LIKE ?", currentSong.like)
        // 当前歌曲是否是喜欢
        if (currentSong.like == 0) {
            currentLike = false
            likeImage.color = UbuntuColors.lightGrey;
        } else {
            currentLike = true
            likeImage.color = UbuntuColors.red;
        }

        // var keys = Object.keys(s);
        // for (var i=0; i < keys.length; i++) {
        //     console.log(keys[i], ": " , s[keys[i]]);
        // }

        image.source = s.picture;
        artist.text = s.artist;
        album.text = "<" + s.albumTitle + "> " + s.publicTime;
        title.text = s.title;
        playMusic.source = s.url;
        console.log("00", s.url)
        playMusic.play();
    }

    /**
     * 标记喜欢
     */
    function song_like() {
        var isLogin = isLoginDouban();
        if (!isLogin || !currentSong) {
            return;
        }
        var user = Database.getUser();
        var sid = currentSong.sid;
        sid = String(sid);
        song.like(user.user_id, user.expire, user.token, sid);
        likeImage.color = UbuntuColors.red;
        currentLike = true;
    }

    /**
     * 标记不喜欢
     */
    function song_unlike() {
        var isLogin = isLoginDouban();
        if (!isLogin || !currentSong) {
            return;
        }
        var user = Database.getUser();
        var sid = currentSong.sid;
        sid = String(sid);
        song.unlike(user.user_id, user.expire, user.token, sid);
        likeImage.color = UbuntuColors.lightGrey;
        currentLike = false;
    }

    /**
     * 标记不再播放
     */
    function song_delete() {
        var isLogin = isLoginDouban();
        if (!isLogin || !currentSong) {
            return;
        }
        var user = Database.getUser();
        var sid = currentSong.sid;
        sid = String(sid);
        song.del(user.user_id, user.expire, user.token, sid);
    }

    /**
     * 播放音乐
     */
    function song_play() {
        playMusic.play();
    }

    /**
     * 暂停音乐
     */
    function song_pause() {
        playMusic.pause();
    }

    /**
     * 停止音乐
     */
    function song_stop() {
        playMusic.stop();
    }

    /**
     * 是否登录豆瓣
     */
    function isLoginDouban() {
        if (Database.getUser()) {
            return true
        } else {
            return false
        }
    }

    /**
     * 是否登录微博
     */
    function isLoginWeibo() {
        if (Database.getWeiboAuth()) {
            return true
        } else {
            return false
        }
    }

    /**
     * 同步离线歌曲
     */
    function syncOffMusic() {
        var douban_user = Database.getUser();
        // TODO: set count
        var offline_music_count = 20 - song.syncCount();
        if (douban_user && offline_music_count > 0) {
            addNotification(doubanPage, i18n.tr("Start Sync songs..."))
            song.syncMusic("-3", douban_user.user_id, douban_user.expire, douban_user.token, offline_music_count);
        }
    }

    /**
     * 添加通知
     */
    function addNotification(page, text, duration) {
        var noti = Qt.createComponent("../components/Notification.qml")
        noti.createObject(page, {text: text, duration: duration})
    }

    /**
     * 检查网络连接
     */
    function check_network() {
       return NetworkingStatus.online;
    }

    /**
     * 启动
     */
    function start() {
        console.log("------ START ------");

        // 检查网络
        var is_online = check_network();
        if (!is_online) {
            addNotification(doubanPage, i18n.tr("No network.\nPlay offline music now..."), 6);
        }

        // 播放歌曲
        song_next();

        // 检查是否需要同步歌曲
        var config_sync = Database.getConfig("sync");
        if (config_sync == "true" && is_online) {
            // 同步离线歌曲
            syncOffMusic();
        }
    }

    // =============================================================
    
}
