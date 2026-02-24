{ inputs, config, lib, pkgs, globalArgs, ... }: {
  sops.defaultSopsFile = "${inputs.self}/secrets/main.yaml";
  sops.age.keyFile = globalArgs.sopsKeyFile;
  sops.age.generateKey = true;
}
