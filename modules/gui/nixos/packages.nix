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
      themeConfig = { FormPosition = "left"; };
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
    ffmpeg-full

    # Tools
    gparted
    wayland-utils
    alsa-utils
    pgadmin4-desktopmode
    hardinfo2
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
