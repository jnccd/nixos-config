{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/common
    ../../modules/miniserver
  ];

  # --- Bootloader ---

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
