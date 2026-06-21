{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
}
