pragma ComponentBehavior: Bound

import qs.common
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

// The workspaces of one screen, plus a slot for a new one. Dropping a
// workspace header here moves that workspace to this screen.
Rectangle {
    id: column

    required property string monitorName
    readonly property var monitor: Hypr.monitorMap[monitorName] ?? null

    radius: Theme.radius
    color: dropArea.containsDrag ? Theme.highlightLow : "transparent"
    border.color: dropArea.containsDrag ? Theme.foam : "transparent"
    border.width: 2

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing
        spacing: Theme.spacing

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: column.monitorName + (column.monitor?.focused ? "  ·  focused" : "")
            color: column.monitor?.focused ? Theme.text : Theme.subtle
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: flow.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Flow {
                id: flow

                // Centers the cards in the column, whatever the number per row.
                readonly property int perRow: Math.max(1, Math.floor((parent.width + spacing) / (Theme.cardWidth + spacing)))
                width: perRow * (Theme.cardWidth + spacing) - spacing
                x: (parent.width - width) / 2
                spacing: Theme.padding

                Repeater {
                    model: ScriptModel {
                        values: OverviewState.workspacesOf(column.monitorName)
                    }
                    delegate: WorkspaceCard {
                        required property int modelData
                        wsId: modelData
                        monitorName: column.monitorName
                    }
                }

                WorkspaceCard {
                    wsId: Stage.freeWorkspace
                    monitorName: column.monitorName
                    isNew: true
                }
            }
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["workspace"]
        onDropped: drop => {
            const ws = OverviewState.dragPayload;
            const current = Hypr.workspaces.find(w => w.id === ws);
            if (current && current.monitor !== column.monitorName)
                Hypr.batch([`moveworkspacetomonitor ${ws} ${column.monitorName}`]);
            drop.accept();
        }
    }
}
