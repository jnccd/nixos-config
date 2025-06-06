{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # KDE
    plasma-panel-colorizer
    kdePackages.filelight
    kdePackages.kate
    kdePackages.kcalc
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

    # Tools
    gparted
    wayland-utils
    alsa-utils
    pgadmin4-desktopmode
    hardinfo2

    # Productivity
    libreoffice-qt6-fresh
    thunderbird
    anki

    plemoljp-nf # Neovim fonts
  ];
}
