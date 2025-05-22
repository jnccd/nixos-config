{ config, lib, pkgs, ... }:
with lib; {
  options.gaming.enabled = mkOption {
    type = types.bool;
    default = false;
    description = "Only enable if you are a T R U E EBIC gamer!!";
  };

  config = mkIf config.gaming.enabled {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    environment.systemPackages = [ pkgs.dolphin-emu ];
  };
}
