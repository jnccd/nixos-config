{
  inputs,
  config,
  lib,
  pkgs,
  hostArgs,
  system,
  globalArgs,
  ...
}:
let
  enable = hostArgs.deepseekHarness.enabled or false;
  webAutostartInSandbox = hostArgs.deepseekHarness.webAutostartInSandbox or false;
in
{
  # If it doesnt work use this: ´nix profile install github:moraxyc/deepseek-harness.nix/73fbdff82d6d21057e0476effdaabf3a657e3e1e#presets.web --accept-flake-config´

  imports = lib.optionals enable [ inputs.deepseek-harness.nixosModules.default ];

  programs.dsh = lib.mkIf enable {
    enable = true;

    profiles.web = {
      bundles = [ pkgs.dsh.bundles.web-ui ];
      mode = "mutable";
    };
  };

  # Add the cachix binary cache for deepseek harness, if enabled. This is needed to get the web-ui bundle.
  nix.settings = lib.mkIf enable {
    substituters = [ "https://deepseek-harness-nix.cachix.org" ];
    trusted-public-keys = [
      "deepseek-harness-nix.cachix.org-1:5NrkwLN9veNMhiINtU5ZeV4isXFhFsOwn6Ms7J1M+TA="
    ];
  };

  # A .desktop in /etc/xdg/autostart is global, so the onlyUser guard in the
  # launcher is what keeps this to the sandbox account. It still only ever
  # runs when that user logs into a KDE session.
  environment.etc = lib.mkIf webAutostartInSandbox (
    lib.custom.mkGuiSessionAutostart {
      appName = "dsh-web";
      shellCommand = "dsh --profile web";
      onlyUser = globalArgs.sandboxUser.name;
      description = "DeepSeek Harness web UI (sandbox user)";
    }
  );
}
