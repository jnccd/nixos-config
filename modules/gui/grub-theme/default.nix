{ config, lib, pkgs, globalArgs, ... }:
let crossgrub = import ./crossgrub.nix { inherit pkgs lib; };
in {
  boot.loader.grub.theme = "${crossgrub}";
  boot.loader.grub.splashImage = "${crossgrub}/background.png";
}
