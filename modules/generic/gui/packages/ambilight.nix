{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  options.dobikoConf.ambilight.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enables ambilight packages";
  };

  config = lib.mkIf config.dobikoConf.ambilight.enabled {
    environment.systemPackages = with pkgs; [
      hyperhdr

    ];

    environment.etc = lib.custom.mkGuiAppAutostart {
      appName = "hyperhdr";
      repoName = "hyperhdr";
      repoUrl = "unused";
      launcherScript = ''
        exec ${lib.getExe pkgs.hyperhdr}
      '';
    };
  };
}
