pragma Singleton

import qs.common
import qs.services
import Quickshell
import QtQuick

// Overview session state: visibility, search filter, keyboard cursor,
// multi-selection and the drag in progress. Also owns the layout order
// (screens, workspaces, windows) so the view and keyboard navigation agree.
Singleton {
    id: root

    property bool open: false
    property string filter: ""
    property var selection: []
    // Window highlighted by keyboard navigation; Enter focuses it.
    property string cursor: ""

    property bool dragging: false
    property string dragKind: ""      // "window" or "workspace"
    property var dragPayload: null    // addresses, or a workspace id
    property string dragLabel: ""
    property var dragClient: null
    property point dragPos

    signal dropRequested()

    onFilterChanged: cursor = firstMatch()

    function toggle(): void {
        if (open)
            close();
        else
            show();
    }

    function show(): void {
        Hypr.refresh();
        filter = "";
        cursor = "";
        selection = [];
        open = true;
    }

    function close(): void {
        cancelDrag();
        open = false;
    }


    // --- Layout order ---

    // Screens from left to right, like the real monitors.
    readonly property var monitorNames: Hypr.monitors.slice()
        .sort((a, b) => a.x - b.x || a.y - b.y)
        .map(m => m.name)

    // Regular workspaces, plus stage workspaces that only exist backstage
    // (their stage window was closed while they were not displayed).
    function workspacesOf(monitorName: string): var {
        const ids = new Set();
        for (const w of Hypr.workspaces) {
            if (w.monitor !== monitorName)
                continue;
            const id = w.id > 0 ? w.id : Stage.stageOf(w.name);
            if (id > 0)
                ids.add(id);
        }
        return [...ids].sort((a, b) => a - b);
    }

    function windowsOf(ws: int): var {
        return Hypr.clients
            .filter(c => c.workspace.id === ws)
            .sort((a, b) => a.at[0] - b.at[0] || a.at[1] - b.at[1])
            .map(c => c.address);
    }

    function backstageOf(ws: int): var {
        return Stage.isEnabled(ws) ? Stage.stripOf(ws).map(c => c.address) : [];
    }

    // Every window in the order it appears on screen.
    readonly property var order: monitorNames.reduce((all, monitor) =>
        workspacesOf(monitor).reduce((acc, ws) => acc.concat(windowsOf(ws), backstageOf(ws)), all), [])


    // --- Search & keyboard ---

    function matches(client: var): bool {
        if (filter === "")
            return true;
        const needle = filter.toLowerCase();
        return [Names.displayName(client), client?.title, client?.class]
            .some(s => (s ?? "").toLowerCase().includes(needle));
    }

    // Most recently used window matching the filter, backstage ones included.
    function firstMatch(): string {
        const found = order
            .map(a => Hypr.clientMap[a])
            .filter(c => c && matches(c))
            .sort((a, b) => a.focusHistoryID - b.focusHistoryID)[0];
        return found?.address ?? "";
    }

    // Moves the cursor through the matching windows, in screen order.
    function step(delta: int): void {
        const candidates = order.filter(a => matches(Hypr.clientMap[a]));
        if (candidates.length === 0)
            return;
        const index = candidates.indexOf(cursor);
        cursor = index < 0
            ? candidates[delta > 0 ? 0 : candidates.length - 1]
            : candidates[(index + delta + candidates.length) % candidates.length];
    }

    function activate(): void {
        const address = cursor !== "" && Hypr.clientMap[cursor] ? cursor : firstMatch();
        if (address !== "")
            Stage.show(address);
        close();
    }


    // --- Selection ---

    function toggleSelected(address: string): void {
        selection = selection.includes(address)
            ? selection.filter(a => a !== address)
            : [...selection, address];
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
