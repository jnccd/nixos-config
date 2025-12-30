{ inputs, config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/generic/common
  ];

  # --- WSL ---

  wsl = {
    enable = true;
    defaultUser = globalArgs.mainUsername;
  };
}
