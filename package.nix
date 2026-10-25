{ writeShellApplication, quickshell }:

# Wraps the QuickShell config in a single command:
#   workspace-manager                     -> runs the daemon
#   workspace-manager <target> <fn> [..]  -> calls its IPC (e.g. `overview toggle`)
# hyprctl is taken from the session's PATH so it always matches the running Hyprland.
writeShellApplication {
  name = "workspace-manager";
  runtimeInputs = [ quickshell ];
  text = ''
    config=${./config}

    case "''${1:-daemon}" in
      daemon) exec quickshell --path "$config" --no-duplicate ;;
      *) exec quickshell --path "$config" ipc call "$@" ;;
    esac
  '';
}
