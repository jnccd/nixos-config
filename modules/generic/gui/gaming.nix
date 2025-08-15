{ config, lib, pkgs, ... }: {
  options.dobikoConf.gaming.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Only enable if you are a T R U E EBIC gamer!!";
  };

  config = lib.mkIf config.dobikoConf.gaming.enabled {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    environment.systemPackages = with pkgs; [
      dolphin-emu
      shadps4
      lutris

    ];
  };
}
