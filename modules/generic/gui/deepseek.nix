{
  inputs,
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
let
  enableDeepseekHarness = lib.custom.unwrapOverrideSet globalArgs.enableDeepseekHarness;
in
if !enableDeepseekHarness then
  { }
else
  {
    imports = [
      inputs.deepseek-harness.nixosModules.default
    ];

    nixpkgs.overlays = [
      inputs.deepseek-harness.overlays.default
    ];

    environment.systemPackages = [ pkgs.dsh.dsh ];

    programs = {
      dsh = {
        enable = true;
        profiles.tui.bundles = [ pkgs.dsh.bundles.tui ];
        defaultProfile = "nix-tui";
      };
    };
  }
