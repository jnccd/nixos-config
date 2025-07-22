{ config, lib, pkgs, globalArgs, ... }: {
  environment.systemPackages = with pkgs; [
    home-manager

    # Networking
    git
    curl
    wget
    lynx
    dig

    # Terminals
    bash
    nushell

    # System Info
    htop
    neofetch
    glances
    powerjoular
    nix-tree

    # Security
    sops
    age

    # Coding
    neovim
    nixfmt-classic
    nil # LSP for nix lang

    zip
    unzip

    screen # I use this extensively for services
  ];
}
