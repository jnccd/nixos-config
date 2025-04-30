# !Flakeless behaviour! sudo nixos-rebuild switch
{ config, lib, pkgs, globalArgs, hostname, ... }: 
{
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/common/nixos.nix
  ];

  # --- WSL ---

  wsl.enable = true;
  wsl.defaultUser = "dobiko";
}
