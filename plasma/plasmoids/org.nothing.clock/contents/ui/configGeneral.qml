import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_use24h: use24h.checked

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: use24h
            Kirigami.FormData.label: i18n("Time format:")
            text: i18n("24-hour clock")
        }
    }
}
