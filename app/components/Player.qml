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
    property bool loading: false
    property bool playOffline: false
    property int playOfflineIndex: 0
    property var currentMusic
    readonly property bool isPlaying: player.playbackState === MediaPlayer.PlayingState
    readonly property var playbackState: mediaPlayerLoader.status == Loader.Ready ? mediaPlayerLoader.item.playbackState : MediaPlayer.StoppedState

    signal stopped()

    /**
     * Play next music
     */
    function nextMusic() {
        player.loading = true
        if (networkingStatus() && !playOffline) {
            DoubanMusic.next()
        } else {
            if (playOfflineIndex == offlineMusicList.length) {
                playOfflineIndex = 0
            }
            var music = offlineMusicList[playOfflineIndex]
            playOfflineIndex += 1
            doubanAPIHandler.musicLoaded(music);
        }
    }

    Connections {
        target: doubanAPIHandler
        onMusicLoaded: {
            playMusic(music)
        }
    }

    /**
     * skip current music
     */
    function skip() {
        player.loading = true
        if (networkingStatus() && !playOffline) {
            var sid = player.currentMusic ? player.currentMusic.sid : "";
            var pt = String((player.position/1000).toFixed(1));
            // wait signal musicLoaded
            DoubanMusic.skipMusic(sid, pt, player.currentMetaChannelID);
        } else {
            if (playOfflineIndex == offlineMusicList.length) {
                playOfflineIndex = 0
            }
            // playMusic(offlineMusicList[playOfflineIndex])
            var music = offlineMusicList[playOfflineIndex]
            playOfflineIndex += 1
            doubanAPIHandler.musicLoaded(music);
        }
    }

    /**
     * Change channel
     */
    function changeChannel(channel_id) {
        player.loading = true
        DoubanMusic.changeChannel(channel_id);
    }

    Connections {
        target: doubanAPIHandler
        onChannelChanged: {
            playMusic(music)
        }
    }

    /**
     * Report end
     */
    function reportEnd() {
        var pt = String((player.position/1000).toFixed(1));
        DoubanMusic.reportEnd(player.currentMusic.sid, pt, player.currentMetaChannelID);
    }

    /**
     * Play new music
     */
    function playMusic(music) {

        // stop();
        // setSource(filepath);
        // play();

        player.currentMusic = music;
        if (music && music.title) {
            currentMetaTitle = music.title;
            currentMetaArtist = music.artist;
            currentMetaAlbum = "<" + music.albumTitle + "> " + music.publicTime;
            currentMetaArt = "";    // force to change image source
            currentMetaArt = music.picture;
            currentMetaLike = (music.like == 1)
            stop();
            setSource(music.url);
            play();
        } else {
            notification(i18n.tr("No more songs"));
        }


    }

    /**
     * Rate this music
     */
    function rateMusic() {
        var sid = player.currentMusic.sid;
        var pt = String((player.position/1000).toFixed(1));
        DoubanMusic.rateMusic(sid, pt, player.currentMetaChannelID)
        player.currentMetaLike = true;
    }

    /**
     * Unrate this music
     */
    function unrateMusic() {
        var sid = player.currentMusic.sid;
        var pt = String((player.position/1000).toFixed(1));
        DoubanMusic.unrateMusic(sid, pt, player.currentMetaChannelID)
        player.currentMetaLike = false;
    }

    /**
     * Ban this music
     */
    function banMusic() {
        player.loading = true
        var sid = player.currentMusic.sid;
        var pt = String((player.position/1000).toFixed(1));
        DoubanMusic.banMusic(sid, pt, player.currentMetaChannelID);
    }

    Connections {
        target: doubanAPIHandler
        onMusicBanned: {
            player.currentMusic = song;
            if (song.title) {
                currentMetaTitle = song.title;
                currentMetaArtist = song.artist;
                currentMetaAlbum = "<" + song.albumTitle + "> " + song.publicTime;
                currentMetaArt = "";    // force to change image source
                currentMetaArt = song.picture;
                currentMetaLike = (song.like == 1)
                playMusic(song.url);
            } else {
                notification(i18n.tr("No more songs"));
            }
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
                    player.stopped()
                }

                onPlaying: {
                    console.debug("[Signal: Playing] status:", status, ",duration", player.duration)
                }

                onStatusChanged: {
                    console.debug("[Signal: StatusChanged] status:", status, ",duration:", player.duration)
                    player.status = status;
                    if (status == MediaPlayer.EndOfMedia) {
                        // play end
                        playedMetric.increment();
                        if (networkingStatus() && !playOffline) {
                            reportEnd();
                        }
                        nextMusic();
                    } else {
                        if (status == MediaPlayer.Buffered || status == MediaPlayer.Loaded) {
                            loading = false;
                        } else {
                            loading = true;
                        }
                    }
                }
            }
        }
    }

    onCurrentMetaChannelIDChanged: {
        console.debug("[Signal: CurrentMetaChannelIDChanged]: ", currentMetaChannelID, DoubanChannels.channelByID(Number(currentMetaChannelID)).name);
        changeChannel(currentMetaChannelID);
    }

    onCurrentMusicChanged: {
        console.debug("[signal: CurrentMusicChanged]");
    }
}
