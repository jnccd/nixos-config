{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  options.dobikoConf.kde.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable KDE";
  };

  config = lib.mkIf config.dobikoConf.kde.enabled {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = with pkgs; [
      plasma-panel-colorizer
      kdePackages.plasma-browser-integration

      inputs.kwin-effects-better-blur-dx.packages.${stdenv.hostPlatform.system}.default # Wayland
      inputs.kwin-effects-better-blur-dx.packages.${stdenv.hostPlatform.system}.x11

      # Since plasma 6.6 there is OCR support in spectacle, but tesseract needs to be installed manually for it apparently
      tesseract
    ];

    # Spectacle seems to have problems finding the tessdata
    environment.sessionVariables.TESSDATA_PREFIX = "${pkgs.tesseract}/share/tessdata";
  };
}
