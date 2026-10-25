pragma Singleton

import Quickshell
import QtQuick

// Human-readable names and icons for Hyprland clients (hyprctl clients -j).
// displayName() ports the display-names script of Nixos-Workstations so a
// window reads the same here, in the bar and in the switcher.
Singleton {
    id: root

    readonly property var webApps: [
        ["obsidian", "Obsidian"],
        ["deezer", "Deezer"],
        ["netflix", "Netflix"],
        ["calendar.notion", "Notion Calendar"],
        ["todoist", "Todoist"],
        ["whatsapp", "Whatsapp"],
    ]

    function capitalize(text: string): string {
        return text.split(/\s+/).filter(w => w.length > 0)
            .map(w => w[0].toUpperCase() + w.slice(1).toLowerCase())
            .join(" ");
    }

    function displayName(client: var): string {
        if (!client)
            return "";
        const initial = (client.initialTitle ?? "").toLowerCase();
        const title = client.title ?? "";
        const lower = title.toLowerCase();

        if (initial.includes("kitty")) {
            if (lower.startsWith("yazi")) return "Yazi";
            if (lower.startsWith("ncmpcpp")) return "Ncmpcpp";
            if (lower.includes("/") || lower.includes("~")) return "Kitty";
            return capitalize(title) || "Kitty";
        }
        for (const [key, name] of webApps)
            if (initial.includes(key))
                return name;
        return capitalize(client.initialTitle || client.class || "?");
    }

    function iconFor(client: var): string {
        const entry = DesktopEntries.heuristicLookup(client?.class ?? "")
            ?? DesktopEntries.heuristicLookup(client?.initialClass ?? "");
        return Quickshell.iconPath(entry?.icon || client?.class || "", "application-x-executable");
    }
}
