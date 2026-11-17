import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

import "controls" as C

DialogView {
    property var consoleIndex
    title: qsTr("Set console pin")
    buttonText: qsTr("Set")
    buttonEnabled: pin.acceptableInput
    onAccepted: {
        Chiaki.setConsolePin(consoleIndex, pin.text.trim());
        stack.pop();
    }
    Item {
        // Card behind the form
        Rectangle {
            x: formGrid.x - 28
            y: formGrid.y - 18
            width: formGrid.width + 56
            height: formGrid.height + 36
            radius: Theme.radiusLarge
            color: Theme.card
        }

        GridLayout {
            id: formGrid
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 40
            }
            columns: 2
            rowSpacing: 10
            columnSpacing: 20
                        Label {
                            Layout.alignment: Qt.AlignRight
                            text: qsTr("Remote Play PIN (4 digits):")
                        }

                        TextField {
                            id: pin
                            validator: RegularExpressionValidator { regularExpression: /[0-9]{4}/ }
                            echoMode: Chiaki.settings.streamerMode ? TextInput.Password : TextInput.Normal
                            Layout.preferredWidth: 400
                        }
        }

    }
}