{
  inputs,
  config,
  lib,
  pkgs,
  globalArgs,
  hostname,
  ...
}:
{
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/generic

    (
      let
        folderName = "home";
        secretsFile = "nas-synology.yaml";
        mountUser = globalArgs.mainUser.name;
      in
      lib.custom.mkNasMountModule {
        inherit
          inputs
          lib
          config
          globalArgs
          folderName
          secretsFile
          mountUser
          ;
      }
    )
    (
      let
        folderName = "media";
        secretsFile = "nas-minis.yaml";
        mountUser = globalArgs.mainUser.name;
      in
      lib.custom.mkNasMountModule {
        inherit
          inputs
          lib
          config
          globalArgs
          folderName
          secretsFile
          mountUser
          ;
      }
    )
  ];

  # --- Custom Module Settings ---

  dobikoConf.postgres.enabled = true;
  dobikoConf.nvidia.enabled = true;
  dobikoConf.gaming.enabled = true;
  dobikoConf.ambilight.enabled = true;

  # --- Misc ---

  time.hardwareClockInLocalTime = true;

  # --- Bootloader ---

  boot.loader = {
    systemd-boot.enable = false;
    grub.enable = true;
    grub.device = "nodev";
    grub.useOSProber = true;
    grub.efiSupport = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";

    grub.default = "2";
  };
}
