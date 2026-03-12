{ config, lib, pkgs, ... }: {
  config = {
    environment.systemPackages = with pkgs;
      [
        # Browser
        firefox
      ] ++ (if config.dobikoConf.nonEssentialGuiPkgs.enabled then [
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
