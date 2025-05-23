{ config, lib, pkgs, globalArgs, ... }: {
  imports = [
    ./gaming.nix
    ./io.nix
    ./packages.nix
    ./ui.nix

  ];
}
