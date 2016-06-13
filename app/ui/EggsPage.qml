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
        title: "Ubuntu Beijing Hackathon"
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
