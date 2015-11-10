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
     * Play next music
     */
    function nextMusic() {
        var music;
        if (networkingStatus()) {
            music = DoubanMusic.next();
        } else {
            music = storage.getMusic();
        }
        player.currentMusic = music;
        if (music && music.title) {
            currentMetaTitle = music.title;
            currentMetaArtist = music.artist;
            currentMetaAlbum = "<" + music.albumTitle + "> " + music.publicTime;
            currentMetaArt = "";    // force to change image source
            currentMetaArt = music.picture;
            currentMetaLike = (music.like == 1)
            playMusic(music.url);
        } else {
            notification(i18n.tr("No more songs"));
        }
    }

    /**
     * skip current music
     */
    function skip() {
        var music;
        if (networkingStatus()) {
            var sid = player.currentMusic ? player.currentMusic.sid : "";
            var pt = String((player.position/1000).toFixed(1));
            music = DoubanMusic.skipMusic(sid, pt, player.currentMetaChannelID);
        } else {
            music = storage.getMusic();
        }
        player.currentMusic = music;
        if (music && music.title) {
            currentMetaTitle = music.title;
            currentMetaArtist = music.artist;
            currentMetaAlbum = "<" + music.albumTitle + "> " + music.publicTime;
            currentMetaArt = "";    // force to change image source
            currentMetaArt = music.picture;
            currentMetaLike = (music.like == 1)
            playMusic(music.url);
        } else {
            notification(i18n.tr("No more songs"));
        }
    }

    /**
     * Change channel
     */
    function changeChannel(channel_id) {
        var music = DoubanMusic.changeChannel(channel_id);
        player.currentMusic = music;
        if (music && music.title) {
            currentMetaTitle = music.title;
            currentMetaArtist = music.artist;
            currentMetaAlbum = "<" + music.albumTitle + "> " + music.publicTime;
            currentMetaArt = "";    // force to change image source
            currentMetaArt = music.picture;
            currentMetaLike = (music.like == 1)
            playMusic(music.url);
        } else {
            notification(i18n.tr("No more songs"));
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
    function playMusic(filepath) {
        stop();
        setSource(filepath);
        play();
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
        var sid = player.currentMusic.sid;
        var pt = String((player.position/1000).toFixed(1));
        var music = DoubanMusic.banMusic(sid, pt, player.currentMetaChannelID);
        player.currentMusic = music;
        if (music.title) {
            currentMetaTitle = music.title;
            currentMetaArtist = music.artist;
            currentMetaAlbum = "<" + music.albumTitle + "> " + music.publicTime;
            currentMetaArt = "";    // force to change image source
            currentMetaArt = music.picture;
            currentMetaLike = (music.like == 1)
            playMusic(music.url);
        } else {
            notification(i18n.tr("No more songs"));
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
                        if (networkingStatus()) {
                            reportEnd();
                        }
                        nextMusic();
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
