{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # KDE
    plasma-panel-colorizer
    # SDDM
    kdePackages.kdialog
    kdePackages.sddm-kcm # For sddm screen sync
    kdePackages.qtmultimedia # For sddm theme
    (sddm-astronaut.override {
      embeddedTheme = "purple_leaves";
      themeConfig = {
        FormPosition = "right";
        Background = "/etc/global-dotfiles/.login-image.jpeg";
        DateTextColor = "#b7cef1";
        FormBackgroundColor = "#121b2b";
        BlurMax = "48";
        Blur = "0.4";
      };
    })

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
