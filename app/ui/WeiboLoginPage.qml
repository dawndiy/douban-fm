import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Web 0.2
import "../components"

Page {

    property alias title: header.text
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

    head {
        contents: DoubanHeader {
            id: header
            text: i18n.tr("Login Sina Weibo")
            source: Qt.resolvedUrl("../images/weibo_64x64.png")
        }
    }

    WebView {
        id: webView
        anchors.fill: parent
        onLoadingChanged: {
            console.debug("[Signal: LoadingChanged]" + url)
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
                pageStack.pop();
            }
        }
    }
}