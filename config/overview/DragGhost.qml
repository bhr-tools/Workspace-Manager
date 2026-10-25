import qs.common
import qs.components
import QtQuick

// Follows the pointer during a drag and carries the Drag that DropAreas see.
Rectangle {
    id: ghost

    readonly property int count: Array.isArray(OverviewState.dragPayload) ? OverviewState.dragPayload.length : 1

    visible: OverviewState.dragging
    x: OverviewState.dragPos.x - width / 2
    y: OverviewState.dragPos.y - height / 2
    z: 100
    width: row.implicitWidth + Theme.padding * 2
    height: Theme.rowHeight + Theme.spacing
    radius: Theme.radius
    color: Theme.overlay
    border.color: Theme.accent
    border.width: 2

    Drag.active: OverviewState.dragging
    Drag.keys: [OverviewState.dragKind]
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacing

        AppIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: OverviewState.dragClient !== null
            client: OverviewState.dragClient
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: OverviewState.dragLabel + (ghost.count > 1 ? `  +${ghost.count - 1}` : "")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }

    Connections {
        target: OverviewState

        function onDropRequested(): void {
            ghost.Drag.drop();
        }
    }
}
