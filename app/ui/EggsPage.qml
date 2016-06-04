import QtQuick 2.4
import Ubuntu.Components 1.3

import "../components"


Page {
    id: eggsPage

    property bool showToolbar: false
    property int currentIndex: 0

    function getPic() {
        var lst = [
            "ubuntu-01.jpg",
            "ubuntu-02.jpg",
            "ubuntu-03.jpg",
            "ubuntu-04.jpg",
            "ubuntu-05.jpg",
            "ubuntu-06.jpg",
            "ubuntu-07.jpg",
        ];

        currentIndex = currentIndex + 1;
        if (currentIndex > lst.length-1) {
            currentIndex = 0
        }

        return "../images/" + lst[currentIndex];
    }

    header: DoubanHeader {
        title: "Ubuntu Beijing Hackation"
    }

    CrossFadeImage {
        id: fadeImage
        anchors {
            top: eggsPage.header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        fadeStyle: "cross"
        source: "../images/ubuntu-01.jpg"
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            fadeImage.source = getPic();
        }
    }
}
