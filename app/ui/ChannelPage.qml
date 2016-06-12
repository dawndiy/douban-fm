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
    id: channelPage

    header: DoubanHeader {
        title: i18n.tr("Channels")

        leadingActionBar.actions: [
            Action {
                text: i18n.tr("Douban FM")
                onTriggered: {
                    tabs.selectedTabIndex = 0
                }
            },
            Action {
                text: i18n.tr("Channels")
                onTriggered: {
                    tabs.selectedTabIndex = 1
                }
            },
            Action {
                text: i18n.tr("Settings")
                onTriggered: {
                    tabs.selectedTabIndex = 2
                }
            }
        ]
    }

    ChannelList {
        id: channelList
        anchors {
            bottomMargin: musicToolbar.visible ? musicToolbar.height : 0
            top: channelPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        selectedIndex: player.currentMetaChannelIndex

        onClicked: {
            console.debug("[Action: Channel]", index)

            if (index == 1 && !isLoginDouban()) {
                notification(i18n.tr("Please login Douban account!"));
                return;
            }

            player.currentMetaChannelIndex = index;
            player.currentMetaChannelID = DoubanChannels.channel(index).id;
            player.playOffline = false;
            //pageStack.pop();
        }
    }
}
