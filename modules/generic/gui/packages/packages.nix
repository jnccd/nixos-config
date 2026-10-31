{
  inputs,
  config,
  lib,
  pkgs,
  system,
  ...
}:
{
  config = {
    environment.systemPackages =
      with pkgs;
      [
        # Browser
        firefox
      ]
      ++ (
        if config.dobikoConf.nonEssentialGuiPkgs.enabled then
          [
            # Multimedia
            vlc
            inkscape-with-extensions
            kdePackages.kdenlive
            blender
            yt-dlp
            obs-studio
            krita
            libresprite
            jellyfin-desktop
            songrec

            # Monitoring
            mission-center
            qdiskinfo

            # Tools
            kdePackages.filelight
            kdePackages.kcalc
            input-remapper

            # Productivity
            libreoffice-qt6-fresh
            thunderbird
            anki-bin

            # Fonts
            plemoljp-nf # Neovim fonts
            orbitron
          ]
        else
          [ ]
      );
  };
}
