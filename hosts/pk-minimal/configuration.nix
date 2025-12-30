{ inputs, config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ../../modules/generic/common

  ];

  # --- Custom Module Settings ---

  dobikoConf.nonEssentialCommonPkgs.enabled = false;
  dobikoConf.ffmpeg.enabled = false;
  dobikoConf.podman.enabled = false;
  dobikoConf.postgres.enabled = false;
  dobikoConf.dotnet.enabled = false;
  dobikoConf.python.enabled = false;

  # --- .vhd options ---

  virtualisation.diskSize = 8192;
}
