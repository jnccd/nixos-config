{ config, pkgs, globalArgs, ... }:
{
  imports = [
    ./gaming.nix
  ];

  # --- Packages ---

  environment.systemPackages = with pkgs; [
    alsa-utils
    sddm-astronaut
    
    # Neovim fonts
    plemoljp-nf
  ];

  # --- Programs ---

  # ༄

  # --- UI ---

  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    settings = {
      Users.HideUsers = "nixbld1,nixbld10,nixbld11,nixbld12,nixbld13,nixbld14,nixbld15,nixbld16,nixbld17,nixbld18,nixbld19,nixbld2,nixbld20,nixbld21,nixbld22,nixbld23,nixbld24,nixbld25,nixbld26,nixbld27,nixbld28,nixbld29,nixbld3,nixbld30,nixbld31,nixbld32,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9,runner";
    };
    theme = "sddm-astronaut-theme";
  };
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
    wireplumber.enable = true;
  };
}
