{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  options.dobikoConf.dshWebAutostart.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Start `dsh --profile web` in the sandbox user's KDE session at login.

      The `dsh` command comes from a manual profile install rather than from
      this configuration (the deepseek-harness module in
      modules/generic/common/deepseek.nix is currently disabled), so the
      launcher only checks that `dsh` exists on that user's PATH and otherwise
      reports it and does nothing.
    '';
  };

  config = lib.mkIf config.dobikoConf.dshWebAutostart.enabled {
    # A .desktop in /etc/xdg/autostart is global, so the onlyUser guard in the
    # launcher is what keeps this to the sandbox account. It still only ever
    # runs when that user logs into a KDE session.
    environment.etc = lib.custom.mkGuiSessionAutostart {
      appName = "dsh-web";
      shellCommand = "dsh --profile web";
      onlyUser = globalArgs.sandboxUser.name;
      description = "DeepSeek Harness web UI (sandbox user)";
    };
  };
}
