{ inputs, config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/generic/common
  ];

  # --- Custom Module Settings ---

  dobikoConf.postgres.enabled = true;

  # --- WSL ---

  wsl = {
    enable = true;
    defaultUser = globalArgs.mainUser.name;
  };
}
