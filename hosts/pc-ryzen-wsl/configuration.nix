{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/common/nixos
  ];

  # --- WSL ---

  wsl.enable = true;
  wsl.defaultUser = globalArgs.mainUsername;
}
