pragma ComponentBehavior: Bound

import qs.common
import qs.services
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Full-screen overview on the focused screen, with one column per screen laid
// out like the real monitors. Typing filters windows, Enter focuses the first
// match, Escape or a click on the backdrop closes.
Scope {
    LazyLoader {
        active: OverviewState.open

        PanelWindow {
            id: window

            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Qt.alpha(Theme.base, 0.97)
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "workspace-manager-overview"

            MouseArea {
                anchors.fill: parent
                onClicked: OverviewState.close()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.padding * 3
                spacing: Theme.padding * 2

                // --- Search ---

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 420
                    implicitHeight: Theme.rowHeight + Theme.spacing
                    radius: Theme.radius
                    color: Theme.surface
                    border.color: Theme.highlightMed

                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding
                        anchors.rightMargin: Theme.padding
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        selectionColor: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        focus: true
                        onTextChanged: OverviewState.filter = text

                        Keys.onEscapePressed: OverviewState.close()
                        Keys.onReturnPressed: {
                            const address = OverviewState.firstMatch();
                            if (address !== "")
                                Stage.show(address);
                            OverviewState.close();
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === ""
                            text: "Rechercher une fenêtre…"
                            color: Theme.muted
                            font: search.font
                        }
                    }
                }

                // --- Screens ---

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.padding * 2

                    Repeater {
                        model: ScriptModel {
                            values: Hypr.monitors.slice()
                                .sort((a, b) => a.x - b.x || a.y - b.y)
                                .map(m => m.name)
                        }
                        delegate: MonitorColumn {
                            required property string modelData
                            monitorName: modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Glisser : déplacer  ·  Ctrl+clic : sélectionner  ·  Clic milieu : fermer  ·  Glisser un en-tête : changer d'écran"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.smallSize
                }
            }

            DragGhost {}

            Component.onCompleted: search.forceActiveFocus()
        }
    }
}
