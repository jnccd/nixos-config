{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ../../modules/generic/common

  ];

  # --- .vhd options ---

  virtualisation.diskSize = 8192;
}
