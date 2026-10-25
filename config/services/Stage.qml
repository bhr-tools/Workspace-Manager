pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Per-workspace stage manager. On an enabled workspace a single tiled window
// stays on stage; the others wait backstage in a hidden special workspace
// (special:stage-<id>) and are listed in the strip. Hyprland remains the
// source of truth: only the set of enabled workspaces is stored on disk.
Singleton {
    id: root

    property var enabled: []
    property bool loaded: false

    readonly property string prefix: "stage-"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/workspace-manager"

    // Lowest workspace id that is neither in use nor holding a backstage.
    readonly property int freeWorkspace: {
        const used = new Set(Hypr.workspaces.map(w => w.id > 0 ? w.id : stageOf(w.name)));
        let id = 1;
        while (used.has(id))
            id++;
        return id;
    }


    // --- Queries ---

    function specialName(ws: int): string {
        return "special:" + prefix + ws;
    }

    // Workspace id whose backstage is `workspaceName`, or -1.
    function stageOf(workspaceName: string): int {
        const head = "special:" + prefix;
        return workspaceName.startsWith(head) ? parseInt(workspaceName.slice(head.length)) : -1;
    }

    function isEnabled(ws: int): bool {
        return enabled.includes(ws);
    }

    // Tiled windows on the workspace itself; floating ones (dialogs, pickers) are left alone.
    function onStage(ws: int): var {
        return Hypr.clients.filter(c => c.workspace.id === ws && !c.floating && !c.pinned);
    }

    // Backstage windows, most recently used first.
    function stripOf(ws: int): var {
        const name = specialName(ws);
        return Hypr.clients.filter(c => c.workspace.name === name)
            .sort((a, b) => a.focusHistoryID - b.focusHistoryID);
    }

    function focusedWorkspace(): int {
        return Hyprland.focusedWorkspace?.id ?? Hypr.focusedMonitor?.activeWorkspace?.id ?? -1;
    }


    // --- Actions ---

    function toggle(ws: int): void {
        if (ws <= 0)
            return;
        if (isEnabled(ws)) {
            enabled = enabled.filter(w => w !== ws);
            run(stripOf(ws).map(c => `movetoworkspacesilent ${ws},address:${c.address}`));
        } else {
            enabled = [...enabled, ws];
            reconcile();
        }
        save();
    }

    // Focuses a window; a backstage one is put on stage first.
    function show(address: string): void {
        const ws = stageOf(Hypr.clientMap[address]?.workspace.name ?? "");
        run(ws < 0 ? [`focuswindow address:${address}`] : promote(ws, address));
    }

    function cycle(recent: bool): void {
        const ws = focusedWorkspace();
        const strip = isEnabled(ws) ? stripOf(ws) : [];
        if (strip.length > 0)
            show((recent ? strip[0] : strip[strip.length - 1]).address);
    }

    // Moves windows to a workspace; on a stage workspace they land backstage.
    function sendTo(addresses: var, ws: int, monitorName: string, create: bool): void {
        const target = isEnabled(ws) ? specialName(ws) : String(ws);
        const commands = addresses
            .filter(a => {
                const c = Hypr.clientMap[a];
                return c && c.workspace.id !== ws && c.workspace.name !== target;
            })
            .map(a => `movetoworkspacesilent ${target},address:${a}`);
        if (create && commands.length > 0)
            commands.push(`moveworkspacetomonitor ${ws} ${monitorName}`);
        run(commands);
    }

    function goTo(ws: int, monitorName: string): void {
        run([`focusmonitor ${monitorName}`, `workspace ${ws}`]);
    }

    // The window goes on stage first so the workspace is never empty in between.
    function promote(ws: int, address: string): var {
        return [
            `movetoworkspacesilent ${ws},address:${address}`,
            ...onStage(ws).map(c => `movetoworkspacesilent ${specialName(ws)},address:${c.address}`),
            `focuswindow address:${address}`,
        ];
    }

    function run(commands: var): void {
        if (commands.length === 0)
            return;
        Hypr.batch(commands);
        // Let Hyprland apply the batch before judging its state again.
        settle.restart();
    }

    // Brings every enabled workspace back to "one tiled window on stage".
    function reconcile(): void {
        if (!loaded || settle.running)
            return;
        const commands = [];

        // A backstage was revealed (a switcher focused one of its windows):
        // hide it again and put that window on stage instead.
        for (const monitor of Hypr.monitors) {
            const ws = stageOf(monitor.specialWorkspace?.name ?? "");
            if (ws < 0)
                continue;
            if (!monitor.focused)
                commands.push(`focusmonitor ${monitor.name}`);
            commands.push(`togglespecialworkspace ${prefix}${ws}`);
            const active = Hypr.activeClient;
            if (isEnabled(ws) && active?.workspace.name === specialName(ws))
                commands.push(...promote(ws, active.address));
        }

        const focused = focusedWorkspace();
        for (const ws of enabled) {
            const staged = onStage(ws);
            if (staged.length > 1) {
                // The most recently focused window (usually the one just opened) keeps the stage.
                const keep = staged.reduce((a, b) => a.focusHistoryID <= b.focusHistoryID ? a : b);
                for (const c of staged)
                    if (c !== keep)
                        commands.push(`movetoworkspacesilent ${specialName(ws)},address:${c.address}`);
            } else if (staged.length === 0 && Hypr.monitors.some(m => m.activeWorkspace.id === ws)) {
                // The stage window was closed or moved away: the next one steps in.
                const next = stripOf(ws)[0];
                if (next) {
                    commands.push(`movetoworkspacesilent ${ws},address:${next.address}`);
                    if (ws === focused)
                        commands.push(`focuswindow address:${next.address}`);
                }
            }
        }
        run(commands);
    }


    // --- Wiring ---

    Connections {
        target: Hypr

        function onRefreshed(): void {
            root.reconcile();
        }
    }

    Timer {
        id: settle
        interval: 200
        onTriggered: Hypr.refresh()
    }


    // --- Persistence ---

    function save(): void {
        store.setText(JSON.stringify({ enabled: root.enabled }));
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.stateDir]
        onExited: store.path = root.stateDir + "/stage.json"
    }

    FileView {
        id: store

        onLoaded: {
            try {
                root.enabled = JSON.parse(text()).enabled ?? [];
            } catch (e) {
                console.warn("workspace-manager: invalid stage state:", e);
            }
            root.loaded = true;
            Hypr.refresh();
        }
        onLoadFailed: {
            root.loaded = true;
            Hypr.refresh();
        }
    }
}
