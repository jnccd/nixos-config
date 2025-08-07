{ config, lib, pkgs, globalArgs, ... }: {
  environment.systemPackages = with pkgs; [
    home-manager

    # Networking
    git

    # Terminals
    bash
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
    nix-prefetch-git
    nix-prefetch-docker
    pnpm

    zip
    unzip

    screen # I use this extensively for services
  ];
}
