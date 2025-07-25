{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ../../modules/generic/common

  ];

  # --- Custom Module Settings ---

  dobikoConf.ffmpeg.enabled = false;
  dobikoConf.dotnet.enabled = false;

  # --- .vhd options ---

  virtualisation.diskSize = 8192;
}
