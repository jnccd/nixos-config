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

  systemd.services = lib.custom.mkWrappedScreenService rec {
    sessionName = "pipewire-pulse-starter";
    username = globalArgs.mainUser.name;
    scriptDirName = sessionName;
    wantedBy = [ "graphical.target" ];
    requires = [ "graphical.target" ];
    after = [ "graphical.target" ];
    script = pkgs.writeScript "script" ''
      sleep 6
      ${lib.custom.bashGetGuiVarsForUser globalArgs.mainUser.name}
      pipewire-pulse
    '';
  };
}
