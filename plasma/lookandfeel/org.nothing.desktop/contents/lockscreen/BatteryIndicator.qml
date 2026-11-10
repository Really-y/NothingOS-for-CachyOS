/*
    Battery level for laptops: mono percentage + glyph. Hidden on desktops.
    Loaded through a Loader so a missing plugin can never break the lock screen.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.plasma.private.battery
import "nothing"

Row {
    // quiet = AOD status row: smaller, grey
    property bool quiet: false
    spacing: 6
    visible: batteryControl.hasInternalBatteries

    BatteryControlModel { id: batteryControl }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        size: parent.quiet ? 14 : 20
        color: batteryControl.percent <= 10 && !batteryControl.pluggedIn ? Theme.red : (parent.quiet ? Theme.fg2 : Theme.fg)
        name: batteryControl.pluggedIn ? "battery_charging_full"
            : batteryControl.percent >= 95 ? "battery_full"
            : "battery_" + Math.max(0, Math.min(6, Math.floor(batteryControl.percent / 100 * 7))) + "_bar"
    }
    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "%1%", batteryControl.percent)
        color: parent.quiet ? Theme.fg2 : Theme.fg
        size: parent.quiet ? 12 : 11
        Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Battery at %1%", batteryControl.percent)
    }
}
