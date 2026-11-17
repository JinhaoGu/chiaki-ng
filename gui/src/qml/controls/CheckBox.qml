import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import ".."

// Drawn as an iOS/macOS-style switch; behaves like a checkbox.
CheckBox {
    id: control
    spacing: 10
    topPadding: 4
    bottomPadding: 4
    indicator: Rectangle {
        implicitWidth: 38
        implicitHeight: 22
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: height / 2
        color: control.checked ? Theme.accent : "#545458"
        opacity: control.enabled ? 1.0 : 0.4
        border.width: control.visualFocus ? 2 : 0
        border.color: Qt.lighter(Theme.accent, 1.4)
        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 2
            x: control.checked ? parent.width - width - 2 : 2
            color: "white"
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }
    contentItem: Label {
        leftPadding: control.indicator.width + control.spacing
        verticalAlignment: Text.AlignVCenter
        text: control.text
        font: control.font
        color: Theme.textPrimary
        opacity: control.enabled ? 1.0 : 0.4
        visible: control.text.length > 0
    }
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    property bool sendOutput: false

    Keys.onPressed: (event) => {
        switch (event.key) {
        case Qt.Key_Up:
            if (!firstInFocusChain) {
                let item = nextItemInFocusChain(false);
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                if(!sendOutput)
                    event.accepted = true;
            }
            break;
        case Qt.Key_Down:
            if (!lastInFocusChain) {
                let item = nextItemInFocusChain();
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                if(!sendOutput)
                    event.accepted = true;
            }
            break;
        case Qt.Key_Return:
            if (visualFocus) {
                toggle();
                clicked();
            }
            event.accepted = true;
            break;
        }
    }
}
