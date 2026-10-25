import qs.overview
import qs.services
import Quickshell
import Quickshell.Io

// Commands exposed to keybindings: `workspace-manager <target> <function>`.
Scope {
    IpcHandler {
        target: "overview"

        function toggle(): void { OverviewState.toggle(); }
        function open(): void { OverviewState.show(); }
        function close(): void { OverviewState.close(); }
    }

    IpcHandler {
        target: "stage"

        // Enables or disables stage mode on the focused workspace.
        function toggle(): void { Stage.toggle(Stage.focusedWorkspace()); }
        function toggleWorkspace(ws: int): void { Stage.toggle(ws); }
        // Swaps with the most recently used window of the strip.
        function recent(): void { Stage.cycle(true); }
        // Rotates through every window of the strip.
        function next(): void { Stage.cycle(false); }
        function enabled(): string { return Stage.enabled.join(" "); }
    }
}
