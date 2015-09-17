import QtQuick 2.4
import Ubuntu.Components 1.2
import Ubuntu.Components.Popups 1.0

Dialog {
    id: dialog

    signal confirm()

    title: i18n.tr("Log out")
    text: i18n.tr("Log out account ?")

    Row {
        width: parent.width
        spacing: units.gu(1)
        Button {
            text: i18n.tr("logout")
            width: parent.width / 2
            // color: UbuntuColors.orange
            onClicked: {
                confirm();
                PopupUtils.close(dialog);
            }
        }
        Button {
            text: i18n.tr("cancel")
            width: parent.width / 2
            onClicked: PopupUtils.close(dialog)
        }
    }
}

