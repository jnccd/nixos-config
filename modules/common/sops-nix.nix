{ config, lib, pkgs, globalArgs, ... }: {
  sops.defaultSopsFile = ../../secrets/main.yaml;
  sops.age.keyFile =
    "/home/${globalArgs.mainUsername}/.config/sops/age/keys.txt";
  sops.age.generateKey = true;
}
