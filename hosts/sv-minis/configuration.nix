{ inputs, config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix
    ../../modules/private/sv-minis-specific

    ../../modules/generic/common
    ../../modules/machine/miniserver
  ];

  # --- Custom Module Settings ---

  dobikoConf.intel_iGPU.enabled = true;
  dobikoConf.fail2ban.enabled = true;

  # --- Bootloader ---

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
