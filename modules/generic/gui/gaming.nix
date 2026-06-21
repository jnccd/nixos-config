{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  options.dobikoConf.gaming.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Only enable if you are a T R U E EBIC gamer!!";
  };

  config = lib.mkIf config.dobikoConf.gaming.enabled {
    # CachyOS Kernel
    nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
    boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest;

    # Steam
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    # Stuff
    environment.systemPackages = with pkgs; [
      dolphin-emu
      shadps4
      lutris-unwrapped

    ];
  };
}
