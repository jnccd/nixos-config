{ config, lib, pkgs, globalArgs, ... }: 
{
  imports = [
    ../../modules/common/home.nix
    ../../modules/gui/home.nix
  ];
}