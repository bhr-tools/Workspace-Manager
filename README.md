# Workspace Manager

Workspace overview and per-workspace stage manager for Hyprland, built on QuickShell.

- **Overview**: every workspace of every screen, with its windows (icon + title).
  Drag windows between workspaces (or onto "new workspace"), drag a workspace
  header onto another screen, Ctrl+click to select several windows, middle click
  to close, type to filter and Enter to focus the first match.
- **Stage manager**: enabled per workspace. A single tiled window stays on stage,
  the others wait backstage in a strip on the left (click to swap). Floating
  windows are left alone. A newly opened window takes the stage; when the stage
  window closes, the most recent backstage window steps in. Workspaces start in
  regular mode, and stage mode is forgotten once the workspace is closed.

Backstage windows live in hidden special workspaces (`special:stage-<id>`), so
Hyprland stays the source of truth. Only the list of enabled workspaces is
stored, in `~/.local/state/workspace-manager/stage.json`.

## Commands

```sh
workspace-manager                      # daemon (exec-once)
workspace-manager overview toggle
workspace-manager stage toggle         # on the focused workspace
workspace-manager stage recent         # swap with the last used backstage window
workspace-manager stage next           # rotate through backstage windows
```

## Installation (home-manager)

```nix
inputs.workspace-manager.url = "git+file:///home/ben/Dev/Workspace-Manager";

# home.nix
imports = [ inputs.workspace-manager.homeManagerModules.default ];
programs.workspace-manager.enable = true;   # installs it and adds exec-once
```

## Development

```sh
nix develop
quickshell -p ./config                 # live-reloads on save
quickshell -p ./config ipc call overview toggle
```
