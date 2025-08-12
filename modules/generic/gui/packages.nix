{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # KDE
    plasma-panel-colorizer

    # Browser
    firefox
    (vivaldi.overrideAttrs
      (oldAttrs: { vivaldi-ffmpeg-codecs = vivaldi-ffmpeg-codecs; }))
    vivaldi-ffmpeg-codecs
    kdePackages.plasma-browser-integration

    # Multimedia
    vlc
    gimp
    inkscape-with-extensions
    kdePackages.dragon
    kdePackages.kdenlive
    blender
    yt-dlp

    # Tools
    pgadmin4-desktopmode
    kdePackages.filelight
    kdePackages.kate
    kdePackages.kcalc

    # Productivity
    libreoffice-qt6-fresh
    thunderbird
    anki

    plemoljp-nf # Neovim fonts
  ];
}
