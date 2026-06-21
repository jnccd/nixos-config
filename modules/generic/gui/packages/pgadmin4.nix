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

    systemd.services = lib.custom.mkGuiAutostartService {
      serviceName = "pgadmin4-starter";
      username = globalArgs.mainUser.name;
      guiScript = pkgs.writeScript "script" ''
        pgadmin4
      '';
    };
  };
}
