{ config, lib, pkgs, globalArgs, ... }: {
  environment.systemPackages = with pkgs; [
    home-manager

    # Networking
    git
    curl
    wget
    lynx

    # Terminals
    bash
    nushell

    # System Info
    htop
    neofetch

    # Security
    sops
    age

    # Coding
    neovim
    nixfmt-classic
    nil # LSP for nix lang
    # Db Upgrade
    postgresql_16
    postgresql

    screen

    ffmpeg-full
  ];
}
