pragma ComponentBehavior: Bound

import qs.common
import qs.services
import Quickshell
import Quickshell.Wayland
import QtQuick

// Narrow left-hand strip of the windows waiting backstage, as icons. One per
// screen, shown while that screen displays a stage-enabled workspace with
// something backstage; its exclusive zone keeps the stage window beside it.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: strip

        required property ShellScreen modelData
        readonly property int wsId: Hypr.monitorMap[modelData.name]?.activeWorkspace?.id ?? -1
        readonly property var windows: Stage.stripOf(wsId).map(c => c.address)

        screen: modelData
        visible: Stage.isEnabled(wsId) && windows.length > 0
        anchors {
            top: true
            bottom: true
            left: true
        }
        implicitWidth: Theme.stripWidth
        color: "transparent"
        WlrLayershell.namespace: "workspace-manager-stage"

        // Centred vertically; it only scrolls when it no longer fits, and never
        // past its ends.
        ListView {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.gap
            height: Math.min(contentHeight, parent.height - Theme.gap * 2)
            spacing: Theme.spacing / 2
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel {
                values: strip.windows
            }
            delegate: StageTile {
                required property string modelData
                address: modelData
                width: ListView.view.width
            }
        }
    }
}
