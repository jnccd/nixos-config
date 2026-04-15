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

  systemd.services = lib.custom.mkWrappedScreenService {
    sessionName = "pipewire-pulse-starter";
    username = globalArgs.mainUser.name;
    scriptDirName = "pipewire-pulse-starter";
    wantedBy = [ "graphical.target" ];
    requires = [ "graphical.target" ];
    after = [ "graphical.target" ];
    script = pkgs.writeScript "script" ''
      WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_DATA_DIRS="/run/current-system/sw/share" pipewire-pulse
    '';
  };
}
