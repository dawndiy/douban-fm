import QtQuick 2.4
import Ubuntu.Components 1.2
import "../components"

Page {

    property alias title: header.text
    property alias url: webView.url

    Component.onCompleted: {
        webView.url = "https://api.weibo.com/oauth2/authorize?client_id=" + Weibo.key + "&response_type=code&redirect_uri=https://api.weibo.com/oauth2/default.html&display=mobile"
    }

    /**
     * Login weibo in backend
     */
    function loginWeibo(code) {
        var ok = Weibo.login(code);
        if (ok) {
            console.debug("Login weibo success");
            storage.saveWeiboUser(Weibo.uid, Weibo.screenName, Weibo.accessToken);

        } else {
            // TODO: need to do something ?
        }
    }

    head {
        contents: DoubanHeader {
            id: header
            text: i18n.tr("Login Sina Weibo")
            source: Qt.resolvedUrl("../images/weibo_64x64.png")
        }
    }

    WeiboWebView {
        id: webView
        onLoadingChanged: {
            console.debug("[Signal: LoadingChanged]" + url)
            var str = String(url);
            if (str.indexOf("https://api.weibo.com/oauth2/default.html?code=") > -1) {
                var code = str.split("code=")[1]
                url = "";
                loginWeibo(code);
                pageStack.pop();
            } else if (str.indexOf("error_code") > -1) {
                url = "";
                pageStack.pop();
            }
        }
    }
}
