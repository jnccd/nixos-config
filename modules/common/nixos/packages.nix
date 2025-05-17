{ config, lib, pkgs, globalArgs, ... }: {
  environment.systemPackages = with pkgs; [
    home-manager

    git
    curl
    wget
    ffmpeg-full

    htop
    neofetch

    bash
    nushell

    screen
    sops
    age

    neovim
    nixfmt-classic
    nil # LSP for nix lang
  ];
}
