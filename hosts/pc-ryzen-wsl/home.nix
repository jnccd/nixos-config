{ config, lib, pkgs, globalArgs, ... }: 
{
  # --- Imports ---

  imports = [
    ../../modules/common/home.nix
  ];
}