{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # KDE
    plasma-panel-colorizer
    kdePackages.kdbusaddons
    kdePackages.kpackage
    # SDDM
    kdePackages.sddm-kcm
    kdePackages.qtmultimedia # For sddm theme
    (sddm-astronaut.override {
      embeddedTheme = "purple_leaves";
      themeConfig = {
        FormPosition = "right";
        Background = "/etc/global-dotfiles/.login-image.jpeg";
        DateTextColor = "#b7cef1";
        FormBackgroundColor = "#121b2b";
        LoginButtonBackgroundColor = "#6e87b8";
        BlurMax = "48";
        Blur = "0.4";
      };
    })

    # Browser
    firefox
    (vivaldi.overrideAttrs (oldAttrs: {
      dontWrapQtApps = false;
      dontPatchELF = true;
      nativeBuildInputs = oldAttrs.nativeBuildInputs
        ++ [ kdePackages.wrapQtAppsHook ];
    }))
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
    hardinfo2
    mission-center
    gparted
    wayland-utils
    alsa-utils
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
