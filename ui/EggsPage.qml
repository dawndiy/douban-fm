import QtQuick 2.4
import Ubuntu.Components 1.2

import "../components"

Page {

    property alias title: header.text
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

    head {
        contents: DoubanHeader {
            id: header
            text: "Ubuntu Beijing Hackathon"
        }
    }

    CrossFadeImage {
        id: fadeImage
        anchors.fill: parent
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
