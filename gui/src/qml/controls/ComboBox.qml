import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import ".."

ComboBox {
    id: control
    // Filled rounded field instead of the Material outline, like a grouped-list row.
    background: Rectangle {
        implicitWidth: 120
        implicitHeight: 32
        radius: Theme.radiusSmall + 1
        color: control.pressed ? Theme.separator : (control.hovered ? Qt.lighter(Theme.control, 1.12) : Theme.control)
        opacity: control.enabled ? 1.0 : 0.5
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accent
    }
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    implicitContentWidthPolicy: ComboBox.WidestText

    Keys.onPressed: (event) => {
        switch (event.key) {
        case Qt.Key_Up:
            if (!popup.visible) {
                let item = nextItemInFocusChain(false);
                if (!firstInFocusChain && item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            break;
        case Qt.Key_Down:
            if (!popup.visible) {
                let item = nextItemInFocusChain();
                if (!lastInFocusChain && item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            break;
        case Qt.Key_Return:
            if (popup.visible) {
                activated(highlightedIndex);
                popup.close();
            } else {
                popup.open();
            }
            event.accepted = true;
            break;
        }
    }

    Keys.onReleased: (event) => {
        if (event.key == Qt.Key_Return)
            event.accepted = true;
    }
}
