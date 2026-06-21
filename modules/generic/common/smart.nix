{
  config,
  lib,
  pkgs,
  globalArgs,
  isWsl,
  ...
}:
{
  environment.systemPackages = with pkgs; [ smartmontools ];

  services.smartd = {
    enable = !isWsl;

    defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04)";
  };
}
