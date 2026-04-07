{ config, inputs, lib, pkgs, system, globalArgs, ... }: {
  boot.loader.grub.theme =
    "${inputs.crossgrub-theme.defaultPackage."${system}"}";
  boot.loader.grub.splashImage =
    "${inputs.crossgrub-theme.defaultPackage."${system}"}/background.png";
}
