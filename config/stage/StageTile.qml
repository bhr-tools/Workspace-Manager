import qs.common
import qs.components
import qs.services
import QtQuick
import QtQuick.Layouts

// A backstage window: click puts it on stage, middle click closes it.
Rectangle {
    id: tile

    required property string address
    readonly property var client: Hypr.clientMap[address] ?? null

    implicitHeight: content.implicitHeight + Theme.padding * 2
    radius: Theme.radius
    color: area.containsMouse ? Theme.highlightMed : Theme.overlay

    Behavior on color {
        ColorAnimation { duration: Theme.anim }
    }

    ColumnLayout {
        id: content
        anchors.centerIn: parent
        width: parent.width - Theme.padding * 2
        spacing: Theme.spacing / 2

        AppIcon {
            Layout.alignment: Qt.AlignHCenter
            implicitSize: 40
            client: tile.client
        }

        Text {
            Layout.fillWidth: true
            text: Names.displayName(tile.client)
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: tile.client?.title ?? ""
            visible: text !== "" && text !== Names.displayName(tile.client)
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: Theme.smallSize
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
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
}
