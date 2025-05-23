{ config, lib, pkgs, globalArgs, ... }: {
  imports = [
    ./csharp-development.nix
    ./gaming.nix
    ./io.nix
    ./packages.nix
    ./ui.nix

  ];
}
