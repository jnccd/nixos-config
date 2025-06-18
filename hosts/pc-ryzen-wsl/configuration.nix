{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/common
    ../../modules/dev
  ];

  # --- WSL ---

  wsl.enable = true;
  wsl.defaultUser = globalArgs.mainUsername;
}
