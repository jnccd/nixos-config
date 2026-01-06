{ inputs, config, lib, pkgs, globalArgs, ... }: {
  sops.defaultSopsFile = "${inputs.self}/secrets/main.yaml";
  sops.age.keyFile =
    "/home/${globalArgs.mainUser.name}/.config/sops/age/keys.txt";
  sops.age.generateKey = true;
}
