import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

Pane {
    padding: 0
    id: consolePane
    StackView.onActivated: {
        forceActiveFocus(Qt.TabFocusReason);
        if(!Chiaki.autoConnect && !root.initialAsk && !Chiaki.window.directStream)
        {
            root.initialAsk = true;
            if(Chiaki.settings.addSteamShortcutAsk && (typeof Chiaki.createSteamShortcut === "function"))
                root.showRemindDialog(qsTr("Official Steam artwork + controller layout"), qsTr("Would you like to either create a new non-Steam game for chiaki-ng\nor update an existing non-Steam game with the official artwork and controller layout?") + "\n\n" + qsTr("(Note: If you select no now and want to do this later, click the button or press R3 from the main menu.)"), false, () => root.showSteamShortcutDialog(true));
            else if(Chiaki.settings.remotePlayAsk)
            {
                if(!Chiaki.settings.psnRefreshToken || !Chiaki.settings.psnAuthToken || !Chiaki.settings.psnAuthTokenExpiry || !Chiaki.settings.psnAccountId)
                    root.showRemindDialog(qsTr("Remote Play via PSN"), qsTr("Would you like to connect to PSN?\nThis enables:\n- Automatic registration\n- Playing outside of your home network without port forwarding?") + "\n\n" + qsTr("(Note: If you select no now and want to do this later, go to the Config section of the settings.)"), true, () => root.showPSNTokenDialog(false));
                else
                    Chiaki.settings.remotePlayAsk = false;
            }
        }
    }
    Keys.onUpPressed: {
        if(hostsView.currentItem && hostsView.currentItem.visible)
        {
            hostsView.decrementCurrentIndex()
            while(!hostsView.currentItem.visible)
                hostsView.decrementCurrentIndex()
        }
    }
    Keys.onDownPressed: {
        if(hostsView.currentItem && hostsView.currentItem.visible)
        {
            hostsView.incrementCurrentIndex()
            while(!hostsView.currentItem.visible)
                 hostsView.incrementCurrentIndex()
        }
    }
    Keys.onMenuPressed: settingsButton.clicked()
    Keys.onReturnPressed: if (hostsView.currentItem) hostsView.currentItem.connectToHost()
    Keys.onYesPressed: if (hostsView.currentItem) hostsView.currentItem.wakeUpHost()
    Keys.onNoPressed: if (hostsView.currentItem) hostsView.currentItem.deleteHost()
    Keys.onEscapePressed: root.showConfirmDialog(qsTr("Quit"), qsTr("Are you sure you want to quit?"), () => Qt.quit())
    Keys.onPressed: (event) => {
        if (event.modifiers)
            return;
        switch (event.key) {
        case Qt.Key_PageUp:
            if (hostsView.currentItem) hostsView.currentItem.setConsolePin();
            event.accepted = true;
            break;
        case Qt.Key_PageDown:
            if (Chiaki.settings.psnAuthToken) Chiaki.refreshPsnToken();
            event.accepted = true;
            break;
        case Qt.Key_F1:
            if (typeof Chiaki.createSteamShortcut === "function") root.showSteamShortcutDialog(false);
            event.accepted = true;
            break;
        case Qt.Key_F2:
            root.showManualHostDialog();
            event.accepted = true;
            break;
        }
    }

    background: Rectangle { color: Theme.background }

    // Small borderless button with an icon and optional text, like a macOS toolbar item.
    component ToolbarButton: AbstractButton {
        id: tb
        property string iconSource
        property string hint
        focusPolicy: Qt.NoFocus
        implicitHeight: 34
        implicitWidth: row.implicitWidth + (text ? 24 : 18)
        hoverEnabled: true
        background: Rectangle {
            radius: Theme.radiusSmall + 2
            color: tb.down ? Theme.control : (tb.hovered ? Theme.card : "transparent")
        }
        contentItem: Item {
            Row {
                id: row
                anchors.centerIn: parent
                spacing: 6
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18; height: 18
                    sourceSize: Qt.size(36, 36)
                    source: tb.iconSource
                    opacity: 0.9
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: tb.text.length > 0
                    text: tb.text
                    font.pixelSize: Theme.fontBody
                    color: Theme.textPrimary
                }
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: tb.hint.length > 0 && Chiaki.controllers.length > 0
                    width: 18; height: 18
                    sourceSize: Qt.size(36, 36)
                    source: tb.hint
                }
            }
        }
    }

    // Small pill used for console state and tags.
    component StatusPill: Rectangle {
        id: pill
        property alias text: pillLabel.text
        property color tint: Theme.textSecondary
        property bool dot: true
        implicitHeight: 22
        implicitWidth: pillRow.implicitWidth + 16
        radius: height / 2
        color: Qt.rgba(tint.r, tint.g, tint.b, 0.16)
        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6
            Rectangle {
                visible: pill.dot
                anchors.verticalCenter: parent.verticalCenter
                width: 7; height: 7; radius: 3.5
                color: pill.tint
            }
            Label {
                id: pillLabel
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.fontCaption
                font.weight: Font.Medium
                color: pill.tint
            }
        }
    }

    // Secondary action on a console card.
    component CardAction: AbstractButton {
        id: ca
        property string iconSource
        property string hint
        property bool showHint: false
        property color tint: Theme.textPrimary
        focusPolicy: Qt.NoFocus
        hoverEnabled: true
        implicitHeight: 32
        implicitWidth: caRow.implicitWidth + 20
        background: Rectangle {
            radius: Theme.radiusSmall + 2
            color: ca.down ? Theme.separator : (ca.hovered ? Theme.control : Qt.rgba(1, 1, 1, 0.06))
        }
        contentItem: Item {
            Row {
                id: caRow
                anchors.centerIn: parent
                spacing: 6
                Image {
                    visible: ca.showHint && ca.hint.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16; height: 16
                    sourceSize: Qt.size(32, 32)
                    source: ca.hint
                }
                Image {
                    visible: !(ca.showHint && ca.hint.length > 0) && ca.iconSource.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 15; height: 15
                    sourceSize: Qt.size(30, 30)
                    source: ca.iconSource
                    opacity: 0.85
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ca.text
                    font.pixelSize: Theme.fontBody - 1
                    color: ca.tint
                }
            }
        }
    }

    function visibleHostCount() {
        let n = 0;
        for (let i = 0; i < Chiaki.hosts.length; ++i)
            if (Chiaki.hosts[i].display)
                n++;
        return n;
    }

    // ---------------------------------------------------------------- header
    Item {
        id: toolBar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: Theme.margin
            rightMargin: Theme.margin - 8
        }
        height: 76

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34
                sourceSize: Qt.size(68, 68)
                source: "qrc:/icons/chiaking.svg"
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Label {
                    text: "chiaki-ng"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }
                Label {
                    text: qsTr("PlayStation Remote Play") + "  ·  " + Qt.application.version
                    font.pixelSize: Theme.fontCaption
                    color: Theme.textSecondary
                }
            }
        }

        Row {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 4

            ToolbarButton {
                text: qsTr("Refresh PSN")
                iconSource: "qrc:/icons/ui-refresh.svg"
                hint: "qrc:/icons/r1.svg"
                visible: !!Chiaki.settings.psnAuthToken
                onClicked: Chiaki.refreshPsnToken()
            }
            ToolbarButton {
                text: qsTr("Steam Shortcut")
                iconSource: "qrc:/icons/ui-steam.svg"
                hint: "qrc:/icons/l3.svg"
                visible: typeof Chiaki.createSteamShortcut === "function"
                onClicked: root.showSteamShortcutDialog(false)
            }
            ToolbarButton {
                text: qsTr("Add Console")
                iconSource: "qrc:/icons/ui-plus.svg"
                hint: "qrc:/icons/r3.svg"
                onClicked: root.showManualHostDialog()
            }
            ToolbarButton {
                id: settingsButton
                iconSource: "qrc:/icons/ui-gear.svg"
                hint: "qrc:/icons/options.svg"
                onClicked: root.showSettingsDialog()
                ToolTip.visible: hovered
                ToolTip.delay: 600
                ToolTip.text: qsTr("Settings")
            }
        }
    }

    // ------------------------------------------------------- section header
    Item {
        id: sectionHeader
        anchors {
            top: toolBar.bottom
            left: parent.left
            right: parent.right
            leftMargin: Theme.margin
            rightMargin: Theme.margin
        }
        height: 36

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Consoles")
            font.pixelSize: Theme.fontHeadline
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        Row {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 8
            BusyIndicator {
                anchors.verticalCenter: parent.verticalCenter
                width: 20; height: 20
                running: Chiaki.discoveryEnabled
                visible: running
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Find consoles on this network")
                font.pixelSize: Theme.fontBody - 1
                color: Theme.textSecondary
            }
            Switch {
                id: discoverySwitch
                anchors.verticalCenter: parent.verticalCenter
                focusPolicy: Qt.NoFocus
                checked: Chiaki.discoveryEnabled
                onToggled: Chiaki.discoveryEnabled = checked
            }
        }
    }

    // ------------------------------------------------------------- consoles
    ListView {
        id: hostsView
        keyNavigationWraps: true
        anchors {
            top: sectionHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: 8
            leftMargin: Theme.margin
            rightMargin: Theme.margin
            bottomMargin: Theme.margin
        }
        spacing: 10
        clip: true
        model: Chiaki.hosts
        highlightMoveDuration: 120
        onCountChanged: {
            if(!hostsView.currentItem)
                hostsView.incrementCurrentIndex();
            if(!hostsView.currentItem)
                return;
            if(!hostsView.currentItem.visible)
            {
                for(var i = 0; i < hostsView.count; i++)
                {
                    hostsView.incrementCurrentIndex()
                    if(hostsView.currentItem.visible)
                    {
                        break;
                    }
                }
            }
        }
        delegate: ItemDelegate {
            visible: modelData.display
            id: delegate
            width: hostsView.width
            height: modelData.display ? 104 : 0
            highlighted: ListView.isCurrentItem
            hoverEnabled: true
            padding: 0
            onClicked: connectToHost()

            readonly property bool showHints: delegate.highlighted && Chiaki.controllers.length > 0
            readonly property bool awake: modelData.discovered && modelData.state !== "standby"

            function connectToHost() {
                if(modelData.discovered)
                    Chiaki.connectToHost(index, modelData.name);
                else
                    Chiaki.connectToHost(index);
            }

            function wakeUpHost() {
                if(!modelData.discovered && !modelData.duid)
                    Chiaki.wakeUpHost(index);
            }

            function deleteHost() {
                if (modelData.manual)
                    root.showConfirmDialog(qsTr("Delete Console"), qsTr("Are you sure you want to delete this console?"), () => {Chiaki.deleteHost(index)});
                else if (modelData.discovered && !modelData.registered)
                    root.showConfirmDialog(qsTr("Hide Console"), qsTr("Are you sure you want to hide this console?") + "\n\n" + qsTr("Note: You can unhide from the Consoles section of the Settings under Hidden Consoles"), () => Chiaki.hideHost(modelData.mac, modelData.name));
            }

            function setConsolePin() {
                root.showConsolePinDialog(index);
            }

            background: Rectangle {
                radius: Theme.radiusLarge
                color: delegate.down ? Theme.control : (delegate.hovered ? Theme.cardHover : Theme.card)
                border.width: delegate.highlighted && hostsView.activeFocus ? 2 : 0
                border.color: Theme.accent
                Behavior on color { ColorAnimation { duration: 90 } }
            }

            contentItem: RowLayout {
                spacing: 18
                anchors {
                    fill: parent
                    leftMargin: 18
                    rightMargin: 18
                }

                Rectangle {
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 68
                    radius: Theme.radius
                    color: Qt.rgba(0, 0, 0, 0.25)
                    Image {
                        anchors.fill: parent
                        anchors.margins: 6
                        fillMode: Image.PreserveAspectFit
                        source: "image://svg/console-ps" + (modelData.ps5 ? "5" : "4") + (modelData.state == "standby" ? "#light_standby" : "#light_on")
                        sourceSize: Qt.size(width * 2, height * 2)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    RowLayout {
                        spacing: 10
                        Label {
                            text: modelData.name || qsTr("PlayStation")
                            font.pixelSize: Theme.fontHeadline + 1
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }
                        StatusPill {
                            visible: !modelData.duid || modelData.discovered
                            tint: delegate.awake ? Theme.green : (modelData.discovered ? Theme.orange : Theme.textSecondary)
                            text: {
                                if (!modelData.discovered)
                                    return modelData.manual ? qsTr("Manual") : qsTr("Offline");
                                if (modelData.state === "standby")
                                    return qsTr("Rest mode");
                                if (modelData.state === "ready")
                                    return qsTr("Ready");
                                return modelData.state;
                            }
                        }
                        StatusPill {
                            visible: !!modelData.duid && !modelData.discovered
                            tint: Theme.accent
                            text: qsTr("Remote via PSN")
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontBody - 1
                        color: Theme.textSecondary
                        text: {
                            let parts = [];
                            if (modelData.address)
                                parts.push(Chiaki.settings.streamerMode ? qsTr("Address hidden") : modelData.address);
                            if (modelData.mac)
                                parts.push(modelData.registered ? qsTr("Registered") : qsTr("Not registered"));
                            if (modelData.duid && modelData.discovered)
                                parts.push(qsTr("Automatic registration available"));
                            if (modelData.discovered && modelData.manual)
                                parts.push(qsTr("Added manually"));
                            return parts.join("  ·  ");
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontCaption
                        color: Theme.textTertiary
                        text: {
                            if (modelData.duid || !modelData.discovered)
                                return "";
                            let parts = [];
                            if (modelData.app)
                                parts.push(qsTr("Playing %1").arg(modelData.app));
                            if (modelData.titleId)
                                parts.push(modelData.titleId);
                            if (modelData.mac && !Chiaki.settings.streamerMode)
                                parts.push(qsTr("ID %1").arg(modelData.mac));
                            return parts.join("  ·  ");
                        }
                    }
                }

                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6

                    CardAction {
                        text: qsTr("Wake Up")
                        iconSource: "qrc:/icons/ui-power.svg"
                        hint: root.controllerButton("pyramid")
                        showHint: delegate.showHints
                        visible: modelData.registered && !modelData.duid && !modelData.discovered
                        onClicked: delegate.wakeUpHost()
                    }
                    CardAction {
                        text: qsTr("Console PIN")
                        iconSource: "qrc:/icons/ui-key.svg"
                        hint: "qrc:/icons/l1.svg"
                        showHint: delegate.showHints
                        visible: modelData.registered
                        onClicked: delegate.setConsolePin()
                    }
                    CardAction {
                        text: modelData.manual ? qsTr("Delete") : qsTr("Hide")
                        iconSource: modelData.manual ? "qrc:/icons/ui-trash.svg" : "qrc:/icons/ui-hide.svg"
                        hint: root.controllerButton("box")
                        showHint: delegate.showHints
                        tint: modelData.manual ? Theme.red : Theme.textPrimary
                        visible: modelData.manual || (modelData.discovered && !modelData.registered)
                        onClicked: delegate.deleteHost()
                    }
                    AbstractButton {
                        id: connectButton
                        focusPolicy: Qt.NoFocus
                        hoverEnabled: true
                        implicitHeight: 32
                        implicitWidth: connectRow.implicitWidth + 28
                        onClicked: delegate.connectToHost()
                        background: Rectangle {
                            radius: Theme.radiusSmall + 2
                            color: connectButton.down ? Theme.accentPressed : Theme.accent
                            opacity: connectButton.hovered ? 0.92 : 1
                        }
                        contentItem: Item {
                            Row {
                                id: connectRow
                                anchors.centerIn: parent
                                spacing: 6
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 13; height: 13
                                    sourceSize: Qt.size(26, 26)
                                    source: delegate.showHints ? root.controllerButton("cross") : "qrc:/icons/ui-play.svg"
                                }
                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.registered || modelData.duid ? qsTr("Connect") : qsTr("Register")
                                    font.pixelSize: Theme.fontBody - 1
                                    font.weight: Font.Medium
                                    color: "white"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------- empty state
    Column {
        anchors.centerIn: hostsView
        spacing: 14
        visible: consolePane.visibleHostCount() === 0
        Image {
            id: logoImage
            anchors.horizontalCenter: parent.horizontalCenter
            source: "qrc:/icons/chiaking-logo-white.svg"
            sourceSize: Qt.size(180, 180)
            opacity: 0.12
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Chiaki.discoveryEnabled ? qsTr("Looking for consoles…") : qsTr("No consoles yet")
            font.pixelSize: Theme.fontHeadline + 2
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Turn on your PlayStation and connect it to the same network,\nor add it manually with its IP address.")
            font.pixelSize: Theme.fontBody
            color: Theme.textSecondary
        }
    }
}
