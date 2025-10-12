{ config, lib, pkgs, ... }: {
  options.dobikoConf.nonEssentialGuiPkgs.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables nonEssentialGuiPkgs";
  };

  config = {
    environment.systemPackages = with pkgs;
      [
        # Browser
        firefox
      ] ++ (if config.dobikoConf.nonEssentialGuiPkgs.enabled then [
        # Browser
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
        obs-studio
        krita
        libresprite

        # Monitoring
        mission-center
        qdiskinfo

        # Tools
        pgadmin4-desktopmode
        kdePackages.filelight
        kdePackages.kcalc
        input-remapper

        # Productivity
        libreoffice-qt6-fresh
        thunderbird
        anki

        plemoljp-nf # Neovim fonts
      ] else
        [ ]);
  };
}
