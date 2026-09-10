{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Start pipewire-pulse inside the desktop session, per user. As a .desktop
  # entry this is an ordinary session process rather than a root system service
  # reaching into someone's session (the old version ran as a system service
  # under graphical.target, i.e. at the login screen).
  environment.etc = lib.custom.mkGuiAppAutostart {
    appName = "pipewire-pulse-starter";
    repoName = "pipewire-pulse-starter";
    repoUrl = "unused";
    launcherScript = ''
      exec ${pkgs.pipewire}/bin/pipewire-pulse
    '';
    restartOnExit = true;
  };
}
