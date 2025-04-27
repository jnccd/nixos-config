{ config, pkgs, globalArgs, ... }:
{
  imports = [
    ./steam.nix
  ];

  # --- Packages ---

  environment.systemPackages = with pkgs; [
    # Neovim fonts
    plemoljp-nf
  ];

  # --- Programs ---

  # ༄

  # --- UI ---

  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
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
}
