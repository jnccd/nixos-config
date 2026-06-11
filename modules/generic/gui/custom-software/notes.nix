{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  options.dobikoConf.notes.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables notes gui app service";
  };

  config = lib.mkIf config.dobikoConf.notes.enabled {
    systemd.services = lib.custom.mkGuiAppService rec {
      username = globalArgs.mainUser.name;
      repoName = "notes";
      repoUrl = "https://github.com/jnccd/${repoName}";
    };
  };
}
