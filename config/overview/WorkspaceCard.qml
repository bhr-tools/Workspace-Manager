pragma ComponentBehavior: Bound

import qs.common
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

// A workspace and its windows. Windows dropped here move to it (backstage on a
// stage workspace); the header drags the whole workspace to another screen.
// With `isNew`, the card stands for the next free workspace.
Rectangle {
    id: card

    required property int wsId
    required property string monitorName
    property bool isNew: false

    readonly property bool stage: Stage.isEnabled(wsId)
    readonly property bool active: Hypr.monitorMap[monitorName]?.activeWorkspace?.id === wsId
    readonly property var windows: isNew ? [] : Hypr.clients
        .filter(c => c.workspace.id === wsId)
        .sort((a, b) => a.at[0] - b.at[0] || a.at[1] - b.at[1])
        .map(c => c.address)
    readonly property var backstage: stage ? Stage.stripOf(wsId).map(c => c.address) : []

    implicitWidth: Theme.cardWidth
    implicitHeight: Theme.cardHeight
    radius: Theme.radius
    color: dropArea.containsDrag ? Theme.highlightMed : Theme.surface
    border.width: active || dropArea.containsDrag ? 2 : 1
    border.color: dropArea.containsDrag ? Theme.foam : active ? Theme.accent : Theme.highlightLow
    opacity: isNew && !dropArea.containsDrag ? 0.6 : 1

    Behavior on color {
        ColorAnimation { duration: Theme.anim }
    }

    // Clicking the card itself switches to the workspace.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Stage.goTo(card.wsId, card.monitorName);
            OverviewState.close();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing
        spacing: Theme.spacing / 2

        // --- Header ---

        Item {
            Layout.fillWidth: true
            implicitHeight: Theme.rowHeight

            DragHandle {
                anchors.fill: parent
                enabled: !card.isNew
                kind: "workspace"
                payload: card.wsId
                label: "Workspace " + card.wsId
                onActivated: {
                    Stage.goTo(card.wsId, card.monitorName);
                    OverviewState.close();
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing / 2
                spacing: Theme.spacing

                Text {
                    text: card.isNew ? "+" : card.wsId
                    color: card.active ? Theme.accent : Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.titleSize
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: card.isNew ? "Nouveau workspace" : card.windows.length === 0 && card.backstage.length === 0 ? "vide" : ""
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.smallSize
                }

                // Stage mode switch, on top of the header's drag handle.
                Rectangle {
                    visible: !card.isNew
                    implicitWidth: stageLabel.implicitWidth + Theme.spacing * 2
                    implicitHeight: stageLabel.implicitHeight + Theme.spacing / 2
                    radius: height / 2
                    color: card.stage ? Theme.accent : stageArea.containsMouse ? Theme.highlightMed : "transparent"
                    border.color: card.stage ? Theme.accent : Theme.highlightHigh

                    Text {
                        id: stageLabel
                        anchors.centerIn: parent
                        text: "Stage"
                        color: card.stage ? Theme.base : Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: Theme.smallSize
                    }

                    MouseArea {
                        id: stageArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Stage.toggle(card.wsId)
                    }
                }
            }
        }

        // --- Windows ---

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: list.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
                id: list
                width: parent.width
                spacing: 2

                Repeater {
                    model: ScriptModel {
                        values: card.windows
                    }
                    delegate: WindowRow {
                        required property string modelData
                        address: modelData
                        width: list.width
                    }
                }

                Text {
                    visible: card.backstage.length > 0
                    topPadding: Theme.spacing / 2
                    leftPadding: Theme.spacing
                    text: "En coulisse"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.smallSize
                }

                Repeater {
                    model: ScriptModel {
                        values: card.backstage
                    }
                    delegate: WindowRow {
                        required property string modelData
                        address: modelData
                        backstage: true
                        width: list.width
                    }
                }
            }
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["window"]
        onDropped: drop => {
            Stage.sendTo(OverviewState.dragPayload, card.wsId, card.monitorName, card.isNew);
            OverviewState.selection = [];
            drop.accept();
        }
    }
}
