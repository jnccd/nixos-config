{ config, lib, ... }:
with lib;
{
  options.mySteam.enabled = mkOption {
    type = types.bool;
    default = false;
    description = "Enabled?";
  };

  config = {
    programs.steam = mkIf config.mySteam.enabled {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };
  };
}
