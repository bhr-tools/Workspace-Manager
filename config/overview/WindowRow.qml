import qs.common
import qs.components
import qs.services
import QtQuick
import QtQuick.Layouts

// One window inside a workspace card.
//   click: focus (a backstage window is put on stage)  ·  ctrl+click: select
//   middle click: close  ·  drag: move it, or the whole selection if it is part of it
Rectangle {
    id: row

    required property string address
    property bool backstage: false

    readonly property var client: Hypr.clientMap[address] ?? null
    readonly property bool selected: OverviewState.selection.includes(address)

    implicitHeight: Theme.rowHeight
    radius: Theme.radius
    color: selected ? Qt.alpha(Theme.accent, 0.3) : handle.containsMouse ? Theme.highlightMed : "transparent"
    border.color: selected ? Theme.accent : "transparent"
    opacity: !OverviewState.matches(client) ? 0.25 : backstage ? 0.65 : 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing
        anchors.rightMargin: Theme.spacing
        spacing: Theme.spacing

        AppIcon {
            client: row.client
        }

        Text {
            text: Names.displayName(row.client)
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
            Layout.maximumWidth: row.width * 0.5
        }

        Text {
            Layout.fillWidth: true
            text: row.client?.title ?? ""
            visible: text !== Names.displayName(row.client)
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: Theme.smallSize
            elide: Text.ElideRight
        }

        Text {
            text: "flottante"
            visible: row.client?.floating ?? false
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.smallSize
        }
    }

    DragHandle {
        id: handle
        anchors.fill: parent
        kind: "window"
        payload: row.selected ? OverviewState.selection : [row.address]
        label: Names.displayName(row.client)
        client: row.client

        onActivated: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                Hypr.batch([`closewindow address:${row.address}`]);
            } else if (mouse.modifiers & Qt.ControlModifier) {
                OverviewState.toggleSelected(row.address);
            } else {
                Stage.show(row.address);
                OverviewState.close();
            }
        }
    }
}
