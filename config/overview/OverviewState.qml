pragma Singleton

import qs.common
import qs.services
import Quickshell
import QtQuick

// Overview session state: visibility, search filter, multi-selection and the
// drag in progress. Kept outside the view so every card shares it.
Singleton {
    id: root

    property bool open: false
    property string filter: ""
    property var selection: []

    property bool dragging: false
    property string dragKind: ""      // "window" or "workspace"
    property var dragPayload: null    // addresses, or a workspace id
    property string dragLabel: ""
    property var dragClient: null
    property point dragPos

    signal dropRequested()

    function toggle(): void {
        if (open)
            close();
        else
            show();
    }

    function show(): void {
        Hypr.refresh();
        filter = "";
        selection = [];
        open = true;
    }

    function close(): void {
        cancelDrag();
        open = false;
    }


    // --- Selection & search ---

    function toggleSelected(address: string): void {
        selection = selection.includes(address)
            ? selection.filter(a => a !== address)
            : [...selection, address];
    }

    function matches(client: var): bool {
        if (filter === "")
            return true;
        const needle = filter.toLowerCase();
        return [Names.displayName(client), client?.title, client?.class]
            .some(s => (s ?? "").toLowerCase().includes(needle));
    }

    // Most recently used window matching the filter, backstage ones included.
    function firstMatch(): string {
        const found = Hypr.clients
            .filter(c => c.workspace.id > 0 || Stage.stageOf(c.workspace.name) > 0)
            .filter(c => matches(c))
            .sort((a, b) => a.focusHistoryID - b.focusHistoryID)[0];
        return found?.address ?? "";
    }


    // --- Drag & drop ---

    function beginDrag(kind: string, payload: var, label: string, client: var, pos: point): void {
        dragKind = kind;
        dragPayload = payload;
        dragLabel = label;
        dragClient = client;
        dragPos = pos;
        dragging = true;
    }

    function moveDrag(pos: point): void {
        dragPos = pos;
    }

    function endDrag(): void {
        if (!dragging)
            return;
        dropRequested();
        dragging = false;
    }

    function cancelDrag(): void {
        dragging = false;
    }
}
