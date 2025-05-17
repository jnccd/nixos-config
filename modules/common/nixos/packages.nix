{ config, lib, pkgs, globalArgs, ... }: {
  environment.systemPackages = with pkgs; [
    home-manager

    git
    curl
    wget
    ((pkgs.ffmpeg-full.override { withUnfree = true; }).overrideAttrs
      (_: { doCheck = false; }))

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
