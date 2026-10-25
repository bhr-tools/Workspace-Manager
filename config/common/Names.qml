pragma Singleton

import Quickshell
import QtQuick

// Human-readable names and icons for Hyprland clients (hyprctl clients -j).
// Both come from the window's desktop entry (matched by StartupWMClass or
// name), following the same rule as the display-names script of
// Nixos-Workstations: no application is listed here.
Singleton {
    id: root

    function capitalize(text: string): string {
        return text.split(/\s+/).filter(w => w.length > 0)
            .map(w => w[0].toUpperCase() + w.slice(1).toLowerCase())
            .join(" ");
    }

    function entryFor(client: var): var {
        // Reading the list makes callers' bindings re-evaluate once the
        // desktop entries are indexed (the index loads lazily).
        if (!client || DesktopEntries.applications.values.length === 0)
            return null;
        return DesktopEntries.heuristicLookup(client.class ?? "")
            ?? DesktopEntries.heuristicLookup(client.initialClass ?? "");
    }

    function displayName(client: var): string {
        if (!client)
            return "";
        const entry = entryFor(client);
        const title = client.title ?? "";

        // A terminal is named after what runs in it, unless its title is just
        // a shell prompt or a path.
        if (entry?.categories?.includes("TerminalEmulator") && title !== "" && !/[\/~@]/.test(title))
            return capitalize(title);
        if (entry?.name)
            return entry.name[0].toUpperCase() + entry.name.slice(1);
        return capitalize(client.initialTitle || client.class || "?");
    }

    function iconFor(client: var): string {
        return Quickshell.iconPath(entryFor(client)?.icon || client?.class || "", "application-x-executable");
    }
}
