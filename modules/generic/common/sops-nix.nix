{ inputs, config, lib, pkgs, globalArgs, ... }: {
  sops.defaultSopsFile = "${inputs.self}/secrets/main.yaml";
  sops.age.keyFile =
    "/home/${globalArgs.mainUsername}/.config/sops/age/keys.txt";
  sops.age.generateKey = true;
}
