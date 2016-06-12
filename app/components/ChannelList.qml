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
import Ubuntu.Components.ListItems 1.3 as ListItems

Item {
    objectName: "channelList"

    property int selectedIndex: channelLoader.item.selectedIndex

    signal clicked(int index)

    Loader {
        id: channelLoader
        anchors.fill: parent
        asynchronous: true

        sourceComponent: Component {

            ListItems.ItemSelector {
                text: i18n.tr("Channels")
                expanded: true
                model: DoubanChannels.len

                delegate: Component {
                    OptionSelectorDelegate {
                        text: DoubanChannels.channel(index).name
                    }
                }

                onDelegateClicked: channelList.clicked(index)
            }
        }
        onLoaded: {
            item.selectedIndex = channelList.selectedIndex
        }
    }
}
