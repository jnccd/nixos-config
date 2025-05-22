{ config, lib, pkgs, globalArgs, ... }: {
  imports = [
    ./packages.nix

    ./gaming.nix
    ./io.nix
    ./ui.nix
  ];
}
