{
  description = "Workspace overview and per-workspace stage manager for Hyprland, built on QuickShell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      packages = forAllSystems (pkgs: rec {
        workspace-manager = pkgs.callPackage ./package.nix { };
        default = workspace-manager;
      });

      homeManagerModules.default = import ./hm-module.nix self;

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell { packages = [ pkgs.quickshell ]; };
      });
    };
}
