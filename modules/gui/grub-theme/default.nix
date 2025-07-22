{ config, lib, pkgs, globalArgs, ... }: {
  boot.loader.grub.theme = "${import ./crossgrub.nix { inherit pkgs lib; }}";
}
