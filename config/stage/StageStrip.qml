pragma ComponentBehavior: Bound

import qs.common
import qs.services
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Left-hand strip listing the windows waiting backstage. One per screen,
// shown while that screen displays a stage-enabled workspace; its exclusive
// zone keeps the stage window beside it.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: strip

        required property ShellScreen modelData
        readonly property int wsId: Hypr.monitorMap[modelData.name]?.activeWorkspace?.id ?? -1
        readonly property var windows: Stage.stripOf(wsId).map(c => c.address)

        screen: modelData
        visible: Stage.isEnabled(wsId)
        anchors {
            top: true
            bottom: true
            left: true
        }
        implicitWidth: Theme.stripWidth
        color: "transparent"
        WlrLayershell.namespace: "workspace-manager-stage"

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: Theme.gap
            anchors.topMargin: Theme.gap
            anchors.bottomMargin: Theme.gap
            radius: Theme.radius
            color: Theme.surface

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacing
                spacing: Theme.spacing

                Text {
                    Layout.fillWidth: true
                    text: "Stage · " + strip.wsId
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: Theme.smallSize
                    horizontalAlignment: Text.AlignHCenter
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.spacing
                    clip: true
                    model: ScriptModel {
                        values: strip.windows
                    }
                    delegate: StageTile {
                        required property string modelData
                        address: modelData
                        width: ListView.view.width
                    }

                    Text {
                        anchors.fill: parent
                        visible: strip.windows.length === 0
                        text: "Aucune fenêtre\nen coulisse"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.smallSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
