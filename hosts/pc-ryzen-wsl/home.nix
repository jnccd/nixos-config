# home-manager switch -b backup --flake .
{ config, lib, pkgs, globalArgs, ... }: 
{
  # --- Imports ---

  imports = [
    ../../modules/common/home.nix
  ];
}