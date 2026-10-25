self:

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.workspace-manager;
in {
  options.programs.workspace-manager = {
    enable = lib.mkEnableOption "the Hyprland workspace overview and stage manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "The workspace-manager package to use.";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start the daemon with Hyprland (exec-once).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    wayland.windowManager.hyprland.settings.exec-once =
      lib.mkIf cfg.autostart [ "${lib.getExe cfg.package}" ];
  };
}
