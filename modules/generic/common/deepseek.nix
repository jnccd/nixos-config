{
  inputs,
  config,
  lib,
  pkgs,
  hostArgs,
  ...
}:
let
  enable = hostArgs.enableDeepseekHarness or false;
in
{
  # Use this: nix profile install github:moraxyc/deepseek-harness.nix/73fbdff82d6d21057e0476effdaabf3a657e3e1e#presets.web --accept-flake-config

  # # Import the module – it automatically sets the overlay and provides options
  # imports = lib.optionals enable [ inputs.deepseek-harness.nixosModules.default ];

  # # Configure the dsh package and profiles (adds dsh to system packages)
  # programs.dsh = lib.mkIf enable {
  #   enable = true;

  #   # (Optional) set the default profile to 'web' or 'tui'
  #   # defaultProfile = "web";

  #   # (Optional) define custom profiles
  #   # profiles.web = {
  #   #   bundles = [ "web-ui" ];   # bundle names from the catalog
  #   #   mode = "mutable";
  #   # };
  # };

  # # Run the web profile as a systemd service (starts automatically)
  # services.dsh = lib.mkIf enable {
  #   enable = true;
  #   # Optional: port = 3080;
  #   # Optional: extraArgs = [ "--some-flag" ];
  # };
}
