{ config, lib, pkgs, globalArgs, ... }: {
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  systemd.services = lib.custom.mkGuiAutostartService {
    serviceName = "pipewire-pulse-starter";
    username = globalArgs.mainUser.name;
    guiScript = pkgs.writeScript "script" ''
      pipewire-pulse
    '';
  };
}
