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

Item {
    id: doubanAPIHandler

    signal captchaImageLoaded(string captcha_id, string captcha_data)
    signal musicLoaded(var music)
    signal channelChanged(var music)
    signal musicBanned(var music)
    signal loginCompleted(var result)

    onCaptchaImageLoaded: {
        console.log("[Signal onCaptchaImageLoaded]", captcha_id)
    }

    onMusicLoaded: {
        if (music) {
            console.log("[Signal onSongLoaded]", music.title)
        }
    }

    onChannelChanged: {
        console.log("[Signal onChannelChanged]", music.title)
    }

    onMusicBanned: {
        console.log("[Signal onSongBanned]", music.title)
    }

    onLoginCompleted: {
        console.log("[Signal onLoginCompleted]", result.result)
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
