{
  config,
  lib,
  pkgs,
  globalArgs,
  hostArgs,
  ...
}:
{
  config = {
    environment.systemPackages =
      with pkgs;
      [
        home-manager

        git
        bash

        screen # I use this extensively for services
      ]
      ++ (
        if hostArgs.enableNonEssentialCommonPkgs then
          [
            nushell

            # System Info
            nix-tree
            lm_sensors
            ncdu

            # Security
            sops
            age
            firejail

            # Coding
            neovim
            ripgrep
            nixfmt
            nil # LSP for nix lang

            # Network stuff
            dig
            traceroute

            zip
            unzip
          ]
        else
          [ ]
      );
  };
}
