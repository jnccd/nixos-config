{
  config,
  inputs,
  lib,
  pkgs,
  system,
  globalArgs,
  ...
}:
let
  crossgrub = inputs.crossgrub-theme.defaultPackage."${system}";
in
{
  boot.loader.grub.theme = "${crossgrub}";
  boot.loader.grub.splashImage = "${crossgrub}/background.png";
}
