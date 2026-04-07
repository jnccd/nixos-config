{ config, lib, pkgs, globalArgs, ... }: {
  environment.systemPackages = with pkgs; [ smartmontools ];

  services.smartd = {
    enable = true;

    defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04)";
  };
}
