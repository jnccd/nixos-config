{ inputs, config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/generic

    (let
      folderName = "home";
      secretsFile = "nas.yaml";
      mountUser = globalArgs.mainUser.name;
    in lib.custom.mkNasMountModule {
      inherit inputs lib config globalArgs folderName secretsFile mountUser;
    })
  ];

  # --- Custom Module Settings ---

  dobikoConf.postgres.enabled = true;
  dobikoConf.xfce.enabled = true;
  dobikoConf.niri.enabled = true;
  dobikoConf.wine.enabled = true;

  # --- Bootloader ---

  boot.loader = {
    systemd-boot.enable = false;
    grub.enable = true;
    grub.device = "nodev";
    grub.useOSProber = true;
    grub.efiSupport = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
  };
}
