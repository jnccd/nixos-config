{ config, lib, pkgs, globalArgs, ... }: {
  environment.shellAliases = {
    owo = "echo uwu"; # I owo into the void and the void uwus back
    "cd.." = "cd ..";
    git-pull =
      "git pull && git submodule foreach 'git checkout main || git checkout -b main origin/main && git pull origin main'";

    nix-rb =
      "sudo nixos-rebuild switch --flake /home/${globalArgs.mainUsername}/git/nixos-config?submodules=1 && home-manager switch -b backup --flake /home/${globalArgs.mainUsername}/git/nixos-config?submodules=1 && bash /home/${globalArgs.mainUsername}/git/nixos-config/copy-dotfiles/from-repo-to-home.sh";
    nix-prb = "git-pull && nix-rb";
    nix-gc = "nix-collect-garbage -d";
  };
}
