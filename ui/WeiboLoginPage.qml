import QtQuick 2.4
import Ubuntu.Components 1.2
import QtQuick.LocalStorage 2.0

import "../components"
import "../js/database.js" as Database
import "../js/weibo.js" as WeiboAPI

Page {

    property alias title: header.text
    property alias url: webView.url
    // 主页头部
    head {
        contents: DoubanHeader {
            id: header
            text: ""
            source: "../images/weibo_64x64.png"
        }
    }

    WeiboWebView {
        id: webView
        onLoadingChanged: {
            console.log("___________________________")
            console.log(url)
            var str = String(url);
            if (str.indexOf("https://api.weibo.com/oauth2/default.html?code=") > -1) {
                var code = str.split("code=")[1]
                url = "";
                login_weibo(code);
                pageStack.pop();
            } else if (str.indexOf("error_code") > -1) {
                url = "";
                pageStack.pop();
            }
        }
    }

    Component.onCompleted: {
        console.log(" WEIBO ")
    }

    // =============================================================
    // Javascript
    // =============================================================

    function login_weibo(code) {
        var ok = weibo.login(code);
        if (ok) {
            console.log("login success");
            Database.saveWeiboAuth(weibo.uid, weibo.screenName, weibo.accessToken);
            settingsPage.loginWeiboLabel.text = weibo.screenName;

        } else {
            // TODO: 
        }
    }

    // =============================================================
}
