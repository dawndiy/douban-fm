import QtQuick 2.4

Item {
    id: doubanAPIHandler

    signal captchaImageLoaded(string captcha_id, string captcha_data)
    signal musicLoaded(var music)
    signal channelChanged(var music)
    signal musicBanned(var music)

    onCaptchaImageLoaded: {
        console.log("[Signal onCaptchaImageLoaded]", captcha_id)
    }

    onMusicLoaded: {
        console.log("[Signal onSongLoaded]", music.title)
    }

    onChannelChanged: {
        console.log("[Signal onChannelChanged]", music.title)
    }

    onMusicBanned: {
        console.log("[Signal onSongBanned]", music.title)
    }

    function getVerificationCode() {
        DoubanUser.getVerificationCode()
    }

    /**
     * go-qml can not emit signal from go side,
     * so use a function to emit signal.
     * go-qml will check the count of parameters,
     * so we can't use arguments here, use a argString instead
     */
    function emitSignal(signalString, argString) {
        var signalFunc
        try {
            signalFunc = eval(signalString)
        } catch (e) {
            console.error("[ERROR]", e)
            return
        }

        if (typeof(signalFunc) !== "function") {
            console.log("[ERROR]", '"'+signalString+'"', "is a", typeof(signalFunc), "not a function or signal")
            return
        }
        var args = argString.replace(/ /g, "").split(",")
        try {
            signalFunc.apply(null, args)
        } catch (e) {
            console.error("[ERROR]", e)
        }
    }

    function emitSignalWithObj(signalString, obj) {
        var signalFunc
        try {
            signalFunc = eval(signalString)
        } catch (e) {
            console.error("[ERROR]", e)
            return
        }

        if (typeof(signalFunc) !== "function") {
            console.log("[ERROR]", '"'+signalString+'"', "is a", typeof(signalFunc), "not a function or signal")
            return
        }
        try {
            signalFunc(obj)
        } catch (e) {
            console.error("[ERROR]", e)
        }
    }

}
