{ config, lib, pkgs, ... }:
with lib; {
  options.gaming.enabled = mkOption {
    type = types.bool;
    default = false;
    description = "Only enable if you are a T R U E EBIC gamer!!";
  };

  config = {
    programs.steam = mkIf config.gaming.enabled {
      enable = true;
      remotePlay.openFirewall =
        true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall =
        true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall =
        true; # Open ports in the firewall for Steam Local Network Game Transfers
    };

    environment.systemPackages =
      mkIf config.gaming.enabled [ pkgs.dolphin-emu ];
  };
}
