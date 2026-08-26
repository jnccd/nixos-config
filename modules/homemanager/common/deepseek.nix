{
  inputs,
  config,
  lib,
  pkgs,
  globalArgs,
  hostArgs,
  ...
}:
let
  enableDeepseekHarness = hostArgs.enableDeepseekHarness;

  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    overlays = [ inputs.deepseek-harness.overlays.default ];
  };
in
if !enableDeepseekHarness then
  { }
else
  {
    # Use instead: nix run github:moraxyc/deepseek-harness.nix#presets.web --accept-flake-config

    # imports = [
    #   inputs.deepseek-harness.nixosModules.default
    # ];

    # programs.dsh = {
    #   enable = true;
    #   package = pkgs.dsh;
    #   profiles = {
    #     tui = {
    #       bundles = [
    #         pkgs.dsh.bundles.tui
    #         pkgs.dsh.bundles.web-ui
    #       ];
    #       mode = "mutable";
    #     };
    #   };
    #   defaultProfile = "nix-tui";
    # };
  }
