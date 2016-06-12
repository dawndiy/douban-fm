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

Item {
    id: notification

    property string text: ""
    property int duration: 3

    width: units.gu(20)
    height: label.height + units.gu(2)
    opacity: 0.75
    z: 9999

    Component.onCompleted: {
        notification.anchors.bottomMargin = 0
        timer.start()
    }

    anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
        bottomMargin: -label.height - units.gu(2)

        Behavior on bottomMargin {
            NumberAnimation { duration: 200 }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        Label {
            id: label
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            text: notification.text
            color: "white"
        }
    }

    Timer {
        id: timer
        interval: notification.duration * 1000
        running: true
        repeat: false
        triggeredOnStart: false
        onTriggered: {
            animaDestroy.start()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: animaDestroy.start()
    }

    SequentialAnimation {
        id: animaDestroy

        UbuntuNumberAnimation {
            target: notification.anchors
            property: "bottomMargin"
            to: -label.height-units.gu(2)
        }

        ScriptAction { script: notification.destroy() }
    }
}
