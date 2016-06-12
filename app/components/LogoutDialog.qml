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

