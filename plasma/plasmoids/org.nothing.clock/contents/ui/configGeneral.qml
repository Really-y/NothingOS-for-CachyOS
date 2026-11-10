import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_use24h: use24h.checked
    property alias cfg_showSeconds: showSeconds.checked

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: use24h
            Kirigami.FormData.label: i18n("Time format:")
            text: i18n("24-hour clock")
        }
        QQC2.CheckBox {
            id: showSeconds
            Kirigami.FormData.label: i18n("Seconds:")
            text: i18n("Show seconds dot strip (wide card)")
        }
    }
}
