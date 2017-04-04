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
    id: aboutPage

    property bool showToolbar: false

    header: DoubanHeader {
        title: i18n.tr("About")

        extension: Sections {
            id: sections
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
            }
            actions: [
                Action {
                    text: i18n.tr("About")
                },
                Action {
                    text: i18n.tr("Credits")
                }
            ]
            onSelectedIndexChanged: {
                tabView.currentIndex = selectedIndex
            }
        }
    }

    ListModel {
        id: creditsModel
        Component.onCompleted: initialize()

        function initialize() {
            // Resources
            creditsModel.append({ category: i18n.tr("Resources"), name: i18n.tr("Bugs"), link: "https://github.com/dawndiy/douban-fm/issues" })
            creditsModel.append({ category: i18n.tr("Resources"), name: i18n.tr("Contact"), link: "mailto:dawndiy.dev@gmail.com" })

            // Developers
            creditsModel.append({ category: i18n.tr("Developers"), name: "DawnDIY (" + i18n.tr("Founder") + ")", link: "https://github.com/dawndiy" })

            // Powered By
            creditsModel.append({ category: i18n.tr("Powered by"), name: "go-qml", link: "https://github.com/go-qml/qml" })
        }

    }

    VisualItemModel {
        id: tabs

        Item {
            width: tabView.width
            height: tabView.height

            Flickable {
                id: flickable
                anchors.fill: parent
                contentHeight: layout.height

                Column {
                    id: layout

                    spacing: units.gu(3)
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        topMargin: units.gu(5)
                    }

                    Image {
                        id: appIcon
                        property var clickTime: 0
                        property int clickCount: 0

                        height: width
                        width: Math.min(parent.width/2, parent.height/2)
                        source: Qt.resolvedUrl("../images/logo.png")
                        anchors.horizontalCenter: parent.horizontalCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var now = new Date();
                                var diff = now.getTime() - appIcon.clickTime;
                                if (diff > 250) {
                                    appIcon.clickCount = 0;
                                } else {
                                    appIcon.clickCount += 1;
                                }
                                appIcon.clickTime = now.getTime();
                                if (appIcon.clickCount >= 2) {
                                    console.log("Easter Eggs")
                                    pageStack.push(Qt.resolvedUrl("EggsPage.qml"))
                                    notification(i18n.tr("★★★ Wow! You find this Easter egg!★★★ "), 8)
                                    appIcon.clickCount = 0;
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        Label {
                            width: parent.width
                            textSize: Label.XLarge
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            text: i18n.tr("Douban FM")
                            style: Text.Raised
                        }
                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            // TRANSLATORS: Douban FM version number e.g Version 1.0.0
                            text: i18n.tr("Version %1").arg(ApplicationVersion)
                        }
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        text: i18n.tr("Douban FM unofficial client for Ubuntu.")
                        style: Text.Raised
                    }

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: units.gu(2)
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            text: "(C) 2015, 2016 DawnDIY"
                        }
                        Label {
                            textSize: Label.Small
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            text: i18n.tr("Released under the terms of the GNU GPL v3")
                        }
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        textSize: Label.Small
                        horizontalAlignment: Text.AlignHCenter
                        linkColor: UbuntuColors.blue
                        text: i18n.tr("Source code available on %1").arg("<a href=\"https://github.com/dawndiy/douban-fm\">Github</a>")
                        onLinkActivated: Qt.openUrlExternally(link)
                    }
                }
            }
        }

        Item {
            width: tabView.width
            height: tabView.height

            ListView {
                id: creditsListView

                model: creditsModel
                anchors.fill: parent
                section.property: "category"
                section.criteria: ViewSection.FullString
                section.delegate: ListItemHeader {
                    title: section
                }

                delegate: ListItem {
                    height: creditsDelegateLayout.height
                    divider.visible: false
                    ListItemLayout {
                        id: creditsDelegateLayout
                        title.text: model.name
                        ProgressionSlot {}
                    }
                    onClicked: Qt.openUrlExternally(model.link)
                }
            }

        }

        // Item {
        //     width: tabView.width
        //     height: tabView.height

        //     Column {
        //         anchors {
        //             left: parent.left
        //             right: parent.right
        //             top: parent.top
        //             margins: units.gu(2)
        //         }
        //         Label {
        //             text: "Help"
        //         }
        //     }
        // }
    }

    ListView {
        id: tabView
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            top: aboutPage.header.bottom
        }
        model: tabs
        currentIndex: 0
        // interactive: false
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: UbuntuAnimation.FastDuration

        onCurrentIndexChanged: {
            sections.selectedIndex = currentIndex
        }
    }
}
