{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  tiledmenu-prime = pkgs.stdenv.mkDerivation {
    pname = "tiledmenu-prime";
    version = "1.0.0";
    src = pkgs.fetchzip {
      url = "https://github.com/jnccd/nix-utils/releases/download/v0.0.-1/tiledmenu-prime-v1.0.zip";
      sha256 = "sha256-dfXmpRA5AkIfFB1YGdyNU9UyF4yhol3AJINAOEJ5gnA=";
    };

    dontBuild = true;

    buildInputs = [ pkgs.unzip ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/plasma/plasmoids/com.github.nirwin81.tiledmenuprime/
      unzip ./tiledmenu-prime-v1.0.2.plasmoid -d $out/share/plasma/plasmoids/com.github.nirwin81.tiledmenuprime/
      runHook postInstall
    '';

    passthru.updateScript = pkgs.nix-update-script { };

    meta = with pkgs.lib; {
      description = "A menu based on Windows 10's Start Menu.";
      license = lib.licenses.mit;
      platforms = platforms.linux;
    };
  };
in
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
      tiledmenu-prime

      inputs.kwin-effects-better-blur-dx.packages.${stdenv.hostPlatform.system}.default # Wayland
      inputs.kwin-effects-better-blur-dx.packages.${stdenv.hostPlatform.system}.x11

      # For KDE Spell Checker
      hunspell
      hunspellDicts.en_US
      hunspellDicts.de_DE

      # Since plasma 6.6 there is OCR support in spectacle, but tesseract needs to be installed manually for it apparently
      tesseract
    ];

    # Spectacle seems to have problems finding the tessdata
    environment.sessionVariables.TESSDATA_PREFIX = "${pkgs.tesseract}/share/tessdata";
  };
}
