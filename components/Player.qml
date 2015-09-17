import QtQuick 2.4
import QtMultimedia 5.0

Item {
    objectName: "player"

    property int duration: 1
    property int position: 0
    property int status
    property string currentMetaTitle: ""
    property string currentMetaArtist: ""
    property string currentMetaAlbum: ""
    property string currentMetaArt: ""
    property string currentMetaChannelID: "0"
    property int currentMetaChannelIndex: 0
    property bool currentMetaLike: false
    property var currentMusic
    readonly property bool isPlaying: player.playbackState === MediaPlayer.PlayingState
    readonly property var playbackState: mediaPlayerLoader.status == Loader.Ready ? mediaPlayerLoader.item.playbackState : MediaPlayer.StoppedState

    /**
     * Get music
     */
    function getMusic(channel_id) {
        channel_id = String(channel_id || currentMetaChannelID || "0");
        var music;
        // get music from backend
        if (!networkingStatus()) {
            // no network, get offline music
            music = DoubanMusic.nextOfflineMusic();
        } else if (isLoginDouban()) {
            // logged in, get music with userinfo
            var user = storage.getDoubanUser();
            music = DoubanMusic.nextWithUser(channel_id, user.user_id, user.expire, user.token);
        } else {
            if (channel_id == "-3") {
                notification("Please login Douban account!");
                currentMetaChannelID = "0";
                currentMetaChannelIndex = 0;
                channel_id = 0;
            }
            // get music normally
            music = DoubanMusic.next(channel_id);
        }
        if (music && music.title) {
            console.debug(music.title);
            if (music.like == 1) {
                currentMetaLike = true;
            } else {
                currentMetaLike = false;
            }
        }
        return music;
    }

    /**
     * Play next music
     */
    function nextMusic(channel_id) {
        var music = getMusic(channel_id);
        player.currentMusic = music
        if (music.title) {
            currentMetaTitle = music.title;
            currentMetaArtist = music.artist;
            currentMetaAlbum = "<" + music.albumTitle + "> " + music.publicTime;
            currentMetaArt = "";    // force to change image source
            currentMetaArt = music.picture;
            playMusic(music.url);
        } else {
            notification(i18n.tr("No more songs"));
        }
    }

    /**
     * Play new music
     */
    function playMusic(filepath) {
        stop();
        setSource(filepath);
        play();
    }

    /**
     * Like this music
     */
    function likeMusic() {
        var user = storage.getDoubanUser();
        if (user) {
            DoubanMusic.like(user.user_id, user.expire, user.token, currentMusic.sid)
            currentMetaLike = true;
        }
    }

    /**
     * Like this music
     */
    function dislikeMusic() {
        var user = storage.getDoubanUser();
        if (user) {
            DoubanMusic.dislike(user.user_id, user.expire, user.token, currentMusic.sid)
            currentMetaLike = false;
        }
    }

    /**
     * ban this music
     */
    function banMusic() {
        var user = storage.getDoubanUser();
        if (user) {
            DoubanMusic.ban(user.user_id, user.expire, user.token, currentMusic.sid)
        }
    }

    /**
     * Play music
     */
    function play() {
        mediaPlayerLoader.item.play();
    }

    /**
     * Pause
     */
    function pause() {
        mediaPlayerLoader.item.pause();
    }

    /**
     * Stop
     */
    function stop() {
        mediaPlayerLoader.item.stop();
    }

    /**
     * Play or Pause
     */
    function toggle() {
        if (player.playbackState == MediaPlayer.PlayingState) {
            pause();
        } else {
            play();
        }
    }

    /**
     * Set source of player
     */
    function setSource(filepath) {
        mediaPlayerLoader.item.source = ""; // force to change player source
        mediaPlayerLoader.item.source = Qt.resolvedUrl(filepath);
    }

    // WorkerScript {
    //     id: playerWorker
    //     source: Qt.resolvedUrl("../js/douban.js")
    // }

    Loader {
        id: mediaPlayerLoader
        asynchronous: true

        sourceComponent: Component {

            MediaPlayer {
                muted: false

                onDurationChanged: player.duration = duration
                onPositionChanged: player.position = position

                onStopped: {
                    console.debug("[Signal: Stopped] status:", status)
                }

                onPlaying: {
                    console.debug("[Signal: Playing] status:", status, ",duration", player.duration)
                }

                onStatusChanged: {
                    console.debug("[Signal: StatusChanged] status:", status, ",duration:", player.duration)
                    player.status = status;
                    if (status == MediaPlayer.EndOfMedia) {
                        playedMetric.increment();
                        nextMusic();
                    }
                }
            }
        }
    }

    onCurrentMetaChannelIDChanged: {
        console.debug("[Signal: CurrentMetaChannelIDChanged]: ", currentMetaChannelID, DoubanChannels.channelByID(Number(currentMetaChannelID)).name)
        nextMusic();
    }

    onCurrentMusicChanged: {
        console.debug("[signal: CurrentMusicChanged]");
    }
}
