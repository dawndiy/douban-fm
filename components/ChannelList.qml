import QtQuick 2.0
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0 as ListItems


ListItems.ItemSelector {

    property var selectedChannelID: 0
    property var selectedChannelName: "私人兆赫"

    id: channelList
    text: i18n.tr("Channels")
    anchors.fill: parent
    expanded: true
    model: channels.len
    delegate: Component {
        OptionSelectorDelegate {
            text: channels.channel(index).name
        }
    }
    onDelegateClicked: {
        selectedChannelID = channels.channel(index).id
        selectedChannelName = channels.channel(index).name
    }
}
