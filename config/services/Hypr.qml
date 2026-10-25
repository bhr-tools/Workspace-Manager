pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Snapshot of Hyprland's state as plain hyprctl JSON (clients, monitors,
// workspaces), refreshed after every compositor event. Plain JSON gives
// everything in one consistent read: workspace names, floating state and focus
// history, which the stage manager relies on.
Singleton {
    id: root

    property var clients: []
    property var monitors: []
    property var workspaces: []

    // QML's JS engine has no Object.fromEntries.
    readonly property var clientMap: clients.reduce((map, c) => (map[c.address] = c, map), {})
    readonly property var monitorMap: monitors.reduce((map, m) => (map[m.name] = m, map), {})
    readonly property var focusedMonitor: monitors.find(m => m.focused) ?? monitors[0] ?? null
    readonly property var activeClient: clients.find(c => c.focusHistoryID === 0) ?? null

    property bool pending: false

    signal refreshed()

    function refresh(): void {
        debounce.restart();
    }

    // Runs several dispatchers in one atomic hyprctl call.
    function batch(commands: var): void {
        if (commands.length === 0)
            return;
        Quickshell.execDetached(["hyprctl", "--batch", commands.map(c => "dispatch " + c).join(" ; ")]);
    }


    Component.onCompleted: refresh()

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            root.refresh();
        }
    }

    // Events come in bursts (a window move emits several): read once per burst.
    Timer {
        id: debounce
        interval: 30
        onTriggered: {
            if (snapshot.running)
                root.pending = true;
            else
                snapshot.running = true;
        }
    }

    Process {
        id: snapshot
        command: ["sh", "-c", 'printf \'{"clients":%s,"monitors":%s,"workspaces":%s}\' "$(hyprctl clients -j)" "$(hyprctl monitors -j)" "$(hyprctl workspaces -j)"']

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const state = JSON.parse(text);
                    root.clients = state.clients.filter(c => c.mapped && c.workspace.id !== -1);
                    root.monitors = state.monitors;
                    root.workspaces = state.workspaces;
                    root.refreshed();
                } catch (e) {
                    console.warn("workspace-manager: cannot read hyprctl state:", e);
                }
            }
        }

        onExited: {
            if (root.pending) {
                root.pending = false;
                running = true;
            }
        }
    }
}
