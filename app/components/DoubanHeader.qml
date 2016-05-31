import QtQuick 2.4
import Ubuntu.Components 1.3

Item {

    property alias text: text.text
    property alias source: image.source

    height: units.gu(7)

    Image {
        id: image
        source: Qt.resolvedUrl("../images/logo.png");
        asynchronous: true
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: units.gu(4)
        height: units.gu(4)
    }

    Text {
        id: text
        text: ""
        font.pixelSize: FontUtils.sizeToPixels("large")
        anchors {
            left: image.right
            leftMargin: units.gu(1)
            verticalCenter: parent.verticalCenter
        }
    }

}
