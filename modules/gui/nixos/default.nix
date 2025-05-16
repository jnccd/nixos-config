{ config, lib, pkgs, globalArgs, ... }: {
  imports = [
    ./gaming.nix

  ];

  # --- Packages ---

  environment.systemPackages = with pkgs; [
    firefox
    alsa-utils
    sddm-astronaut
    plemoljp-nf # Neovim fonts
  ];

  # --- Programs ---

  # ༄

  # --- UI ---

  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    settings = {
      Users.HideUsers = (lib.lists.foldl (a: b: a + "," + b) ""
        ((builtins.genList (x: "nixbld" + (builtins.toString x)) 33)
          ++ [ globalArgs.defaultSystemUsername ]));
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
