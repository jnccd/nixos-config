{
  inputs,
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
let
  unwrapOverrideSet =
    val: if builtins.isAttrs val && val ? _type && val._type == "override" then val.content else val;

  enableDeepseekHarness = unwrapOverrideSet globalArgs.enableDeepseekHarness;
in
{
  imports = lib.optionals enableDeepseekHarness [
    inputs.deepseek-harness.nixosModules.default
  ];

  nixpkgs.overlays = lib.optionals enableDeepseekHarness [
    inputs.deepseek-harness.overlays.default
  ];

  environment.systemPackages = lib.optionals enableDeepseekHarness [ pkgs.dsh.dsh ];

  programs = lib.optionalAttrs enableDeepseekHarness {
    dsh = {
      enable = true;
      profiles.tui.bundles = [ pkgs.dsh.bundles.tui ];
      defaultProfile = "nix-tui";
    };
  };
}
