{ config, lib, pkgs, globalArgs, ... }: {
  environment.systemPackages = ([ pkgs.python313 ])
    ++ (with pkgs.python313Packages;
      [
        requests # For hyprland waybar script

      ]);
}
