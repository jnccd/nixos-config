{ config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.nonEssentialCommonPkgs.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables nonEssentialCommonPkgs";
  };

  config = {
    environment.systemPackages = with pkgs;
      [
        home-manager

        git
        bash

        screen # I use this extensively for services
      ] ++ (if config.dobikoConf.nonEssentialCommonPkgs.enabled then [
        nushell

        # System Info
        htop
        btop
        glances
        nix-tree

        # Security
        sops
        age

        # Coding
        neovim
        nixfmt-classic
        nil # LSP for nix lang

        jq
        zip
        unzip
      ] else
        [ ]);
  };
}
