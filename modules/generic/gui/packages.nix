{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Browser
    firefox
    (vivaldi.overrideAttrs
      (oldAttrs: { vivaldi-ffmpeg-codecs = vivaldi-ffmpeg-codecs; }))
    vivaldi-ffmpeg-codecs

    # Multimedia
    vlc
    gimp
    inkscape-with-extensions
    kdePackages.kdenlive
    blender
    yt-dlp

    # Tools
    pgadmin4-desktopmode
    kdePackages.filelight
    kdePackages.kcalc

    # Productivity
    libreoffice-qt6-fresh
    thunderbird
    anki

    plemoljp-nf # Neovim fonts
  ];
}
