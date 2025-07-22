{ config, lib, pkgs, ... }: {
  options.dobikoConf.ffmpeg.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables ffmpeg";
  };

  config = lib.mkIf config.dobikoConf.ffmpeg.enabled {
    environment.systemPackages = with pkgs; [ ffmpeg-full ];
  };
}
