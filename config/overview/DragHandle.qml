import QtQuick

// Mouse area that starts an overview drag once the pointer has moved a few
// pixels, and reports plain clicks otherwise.
MouseArea {
    id: handle

    property string kind
    property var payload
    property string label
    property var client: null

    property bool dragged: false
    property point origin

    signal activated(var mouse)

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: dragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor

    onPressed: mouse => {
        origin = Qt.point(mouse.x, mouse.y);
        dragged = false;
    }

    onPositionChanged: mouse => {
        if (!(pressedButtons & Qt.LeftButton))
            return;
        const scenePos = mapToItem(null, mouse.x, mouse.y);
        if (!dragged && Math.abs(mouse.x - origin.x) + Math.abs(mouse.y - origin.y) > 8) {
            dragged = true;
            OverviewState.beginDrag(kind, payload, label, client, scenePos);
        }
        if (dragged)
            OverviewState.moveDrag(scenePos);
    }

    onReleased: {
        if (dragged)
            OverviewState.endDrag();
    }

    onCanceled: {
        if (dragged)
            OverviewState.cancelDrag();
    }

    onClicked: mouse => {
        if (!dragged)
            activated(mouse);
    }

    // The source may vanish mid-drag (window closed elsewhere): never leave a ghost behind.
    Component.onDestruction: {
        if (dragged)
            OverviewState.cancelDrag();
    }
}
