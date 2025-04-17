# home-manager switch -b backup --flake .
{ config, pkgs, homeStateVersion, username, ... }: 
{
  # --- Imports ---

  imports = [
    ../../modules/common/home.nix
    ../../modules/gui/home.nix
    ../../modules/miniserver/home.nix
  ];
}