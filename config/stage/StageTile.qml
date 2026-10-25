import qs.common
import qs.components
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

// A backstage window as an icon: click puts it on stage, middle click closes
// it, hovering shows its name and title beside the strip.
Rectangle {
    id: tile

    required property string address
    readonly property var client: Hypr.clientMap[address] ?? null

    implicitHeight: width
    radius: Theme.radius
    color: area.containsMouse ? Theme.highlightMed : Qt.alpha(Theme.surface, 0.85)

    Behavior on color {
        ColorAnimation { duration: Theme.anim }
    }

    AppIcon {
        anchors.centerIn: parent
        implicitSize: tile.width * 0.6
        client: tile.client
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                Hypr.batch([`closewindow address:${tile.address}`]);
            else
                Stage.show(tile.address);
        }
    }

    PopupWindow {
        visible: area.containsMouse
        anchor.item: tile
        anchor.edges: Edges.Right
        anchor.gravity: Edges.Right
        anchor.margins.left: Theme.spacing
        implicitWidth: label.implicitWidth + Theme.padding * 2
        implicitHeight: label.implicitHeight + Theme.spacing * 2
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.overlay
            border.color: Theme.highlightMed

            ColumnLayout {
                id: label
                anchors.centerIn: parent
                spacing: 0

                Text {
                    text: Names.displayName(tile.client)
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    Layout.maximumWidth: 360
                    text: tile.client?.title ?? ""
                    visible: text !== "" && text !== Names.displayName(tile.client)
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: Theme.smallSize
                    elide: Text.ElideRight
                }
            }
        }
    }
}
