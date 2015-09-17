import QtQuick 2.4
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0 as ListItems

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
