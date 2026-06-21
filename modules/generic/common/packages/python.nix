{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  options.dobikoConf.python.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables python";
  };

  config = lib.mkIf config.dobikoConf.python.enabled {
    environment.systemPackages = with pkgs; [
      (python3.withPackages (
        ps: with ps; [
          requests

        ]
      ))

      uv
    ];

    environment.shellAliases = {
      upython = "uv run python";
      upip = "uv pip";
    };
  };
}
