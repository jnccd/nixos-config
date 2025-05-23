{ config, lib, pkgs, globalArgs, ... }:
let nixosConfigPath = "/home/${globalArgs.mainUsername}/git/nixos-config";
in {
  environment.shellAliases = {
    owo = "echo uwu"; # I owo into the void and the void uwus back
    "cd.." = "cd ..";

    git-pull =
      "git pull && git submodule foreach 'git checkout main || git checkout -b main origin/main && git pull origin main'";
    git-pull-nixconf =
      "oldPwd=$(pwd) && cd ${nixosConfigPath} && git-pull && cd $oldPwd";

    nix-rb =
      "sudo nixos-rebuild switch --flake ${nixosConfigPath}?submodules=1 && home-manager switch -b backup --flake ${nixosConfigPath}?submodules=1 && bash ${nixosConfigPath}/copy-dotfiles/from-repo-to-home.sh";
    nix-prb = "git-pull-nixconf && nix-rb";
    nix-gc = "nix-collect-garbage -d";
  };
}
