{
  config,
  lib,
  pkgs,
  globalArgs,
  hostArgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [ smartmontools ];

  services.smartd = {
    enable = !hostArgs.enableWslModule; # Donest make sense on wsl

    defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04)"; # Monitor all SMART attributes, run short test daily at 2am and long test every Sunday at 4am
  };
}
