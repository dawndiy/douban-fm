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
import Ubuntu.Components 1.3
import Ubuntu.Web 0.2
import "../components"

Page {
    id: weiboLoginPage

    property bool showToolbar: false
    property alias url: webView.url

    signal loginSuccess()
    signal loginFailed()

    Component.onCompleted: {
        webView.url = "https://api.weibo.com/oauth2/authorize?client_id=" + Weibo.key + "&response_type=code&redirect_uri=https://api.weibo.com/oauth2/default.html&display=mobile"
    }

    /**
     * Login weibo in backend
     */
    function loginWeibo(code) {
        var ok = Weibo.login(code);
        if (ok) {
            var now = +new Date();
            console.debug("Login weibo success at " + now);
            storage.saveWeiboUser(Weibo.uid, Weibo.screenName, Weibo.accessToken, Weibo.expiresIn, now);

        } else {
            console.debug("Login weibo failed");
            notification(i18n.tr("Login weibo failed, please try again!"))
        }
    }

    header: DoubanHeader {
        title: i18n.tr("Login Sina Weibo")
    }

    WebView {
        id: webView
        anchors {
            top: weiboLoginPage.header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        onLoadingChanged: {
            // console.debug("[Signal: LoadingChanged]" + url)
            var str = String(url);
            if (str.indexOf("https://api.weibo.com/oauth2/default.html?code=") > -1) {
                var code = str.split("code=")[1]
                url = "";
                loginWeibo(code);
                loginSuccess();
                pageStack.pop();
            } else if (str.indexOf("error_code") > -1) {
                url = "";
                loginFailed();
                notification(i18n.tr("Login weibo failed!"))
                webView.destroy();
                pageStack.pop();
            }
        }
    }
}
