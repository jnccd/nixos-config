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
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    environment.systemPackages =
      mkIf config.gaming.enabled [ pkgs.dolphin-emu ];
  };
}
