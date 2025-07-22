{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/common
    ../../modules/nix-dev
  ];

  # --- WSL ---

  wsl = {
    enable = true;
    defaultUser = globalArgs.mainUsername;
  };
}
