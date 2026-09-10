{
  inputs,
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  config = lib.mkIf config.dobikoConf.nonEssentialGuiPkgs.enabled {
    environment.systemPackages = with pkgs; [
      pgadmin4-desktopmode

    ];

    environment.etc = lib.custom.mkGuiAppAutostart {
      appName = "pgadmin4";
      repoName = "pgadmin4";
      repoUrl = "unused";
      launcherScript = ''
        exec ${lib.getExe pkgs.pgadmin4-desktopmode}
      '';
    };
  };
}
