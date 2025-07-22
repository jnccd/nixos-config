{ config, lib, pkgs, globalArgs, ... }: {
  boot.loader.grub.theme = "${import ./crossgrub.nix { inherit pkgs lib; }}";
  boot.loader.grub.splashImage =
    "${import ./crossgrub.nix { inherit pkgs lib; }}/background.png";
}
