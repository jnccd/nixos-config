{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/generic/common
    ../../modules/machine/miniserver

    ../../modules/private/nas/transfer.nix
  ];

  # --- Custom Module Settings ---

  dobikoConf.ffmpeg.enabled = false;

  # --- Bootloader ---

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
