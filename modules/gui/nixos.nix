{ pkgs, stateVersion, username, ... }:
{
  # --- UI ---

  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.theme = "Breeze Dark";
  services.desktopManager.plasma6.enable = true;

  # --- IO ---

  # Configure keymap
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };
  console.keyMap = "de";

  services.printing.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Some programs need SUID wrappers
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh.enable = true;
}
