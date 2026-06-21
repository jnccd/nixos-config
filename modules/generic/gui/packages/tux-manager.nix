{
  inputs,
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
  tuxManagerPkg = inputs.tux-manager.packages.${system}.default;
in
{
  environment.systemPackages = (
    if config.dobikoConf.nonEssentialGuiPkgs.enabled then [ tuxManagerPkg ] else [ ]
  );

  security.wrappers.tux-manager = {
    source = "${tuxManagerPkg}/bin/tux-manager";
    capabilities = "cap_perfmon+ep";
    owner = "root";
    group = "root";
    permissions = "0755";
  };
}
