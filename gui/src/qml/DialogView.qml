import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: dialog
    property alias header: headerLabel.text
    property alias title: titleLabel.text
    property alias buttonText: okButton.text
    property alias buttonEnabled: okButton.enabled
    property alias buttonVisible: okButton.visible
    property Item restoreFocusItem
    default property Item mainItem: null

    signal accepted()
    signal rejected()

    function close() {
        root.closeDialog();
    }

    Keys.onEscapePressed: close()

    Keys.onMenuPressed: {
        if (okButton.enabled)
            okButton.clicked()
    }

    StackView.onDeactivating: {
        restoreFocusItem = Window.window.activeFocusItem;
    }

    StackView.onActivated: {
        if (!restoreFocusItem) {
            let item = mainItem.nextItemInFocusChain();
            if (item)
                item.forceActiveFocus(Qt.TabFocusReason);
        } else {
            restoreFocusItem.forceActiveFocus(Qt.TabFocusReason);
            restoreFocusItem = null;
        }
    }

    onMainItemChanged: {
        if (mainItem) {
            mainItem.parent = contentItem;
            mainItem.anchors.fill = contentItem;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        z: -1
    }

    // Page header: back button and title on the left, the page action on the right.
    Item {
        id: toolBar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 64

        Row {
            anchors {
                left: parent.left
                leftMargin: Theme.margin - 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 6

            AbstractButton {
                id: backButton
                focusPolicy: Qt.NoFocus
                hoverEnabled: true
                width: 34; height: 34
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    dialog.rejected();
                    dialog.close();
                }
                background: Rectangle {
                    radius: Theme.radiusSmall + 2
                    color: backButton.down ? Theme.control : (backButton.hovered ? Theme.card : "transparent")
                }
                contentItem: Label {
                    text: "\u2039"
                    font.pixelSize: 30
                    color: Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    topPadding: -4
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Label {
                    id: titleLabel
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }
                Label {
                    id: headerLabel
                    visible: text.length > 0
                    font.pixelSize: Theme.fontCaption
                    color: Theme.textSecondary
                }
            }
        }

        Button {
            id: okButton
            anchors {
                right: parent.right
                rightMargin: Theme.margin
                verticalCenter: parent.verticalCenter
            }
            highlighted: true
            focusPolicy: Qt.NoFocus
            Material.roundedScale: Material.SmallScale
            Material.accent: Theme.accent
            onClicked: dialog.accepted()
            icon.source: root.showControllerHints ? "qrc:/icons/options.svg" : ""
            icon.width: 20
            icon.height: 20
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.separator
        }
    }

    Item {
        id: contentItem
        anchors {
            top: toolBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }
}
