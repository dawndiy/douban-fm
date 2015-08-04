import QtQuick 2.4
import Ubuntu.Web 0.2
import Ubuntu.Components 1.2



WebView {

    property alias url: web.url

    id: web
    anchors.fill: parent

    // Component.onCompleted: {
    //     url = "https://api.weibo.com/oauth2/authorize?client_id=" + weibo.key + "&response_type=code&redirect_uri=https://api.weibo.com/oauth2/default.html&display=mobile"
    // }

    // onLoadingChanged: {
    //     console.log(web.url)
    // }
}
