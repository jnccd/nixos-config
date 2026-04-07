{ config, inputs, lib, pkgs, globalArgs, ... }: {
  boot.loader.grub.theme = "${inputs.crossgrub-theme}";
  boot.loader.grub.splashImage = "${inputs.crossgrub-theme}/background.png";
}
