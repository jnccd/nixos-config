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
in
if !enableDeepseekHarness then
  { }
else
  {
    imports = [
      inputs.deepseek-harness.nixosModules.default
    ];

    programs.dsh = {
      enable = true;
      profiles = {
        tui = {
          bundles = [
            pkgs.dsh.bundles.tui
            pkgs.dsh.bundles.web-ui
          ];
          mode = "mutable";
        };
      };
      defaultProfile = "nix-tui";
    };

    nix.settings = {
      substituters = [ "https://deepseek-harness-nix.cachix.org" ];
      trusted-public-keys = [
        "deepseek-harness-nix.cachix.org-1:5NrkwLN9veNMhiINtU5ZeV4isXFhFsOwn6Ms7J1M+TA="
      ];
    };
  }
