import qs.common
import Quickshell.Widgets
import QtQuick

IconImage {
    property var client: null

    implicitSize: 20
    asynchronous: true
    source: Names.iconFor(client)
}
