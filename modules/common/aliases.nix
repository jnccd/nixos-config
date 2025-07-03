{ config, lib, pkgs, globalArgs, ... }: {
  environment.shellAliases = {
    owo = "echo uwu"; # I owo into the void and the void uwus back
    "cd.." = "cd ..";
    scrn-ls = ''
      sudo bash -c '
        for home in $(cut -d: -f6 /etc/passwd | grep -v '/var/empty'); do 
          if [ -d $home/.screen ] && [ -x $home/.screen ]; then
            cd $home/.screen && echo $home && ls; 
          fi; 
        done'
    '';

    git-pull =
      "git pull && git submodule foreach 'git checkout main && git pull'";
    git-pull-nixconf =
      "oldPwd=$(pwd) && cd ${globalArgs.nixosConfigPath} && git-pull && cd $oldPwd";

    nix-rb =
      "bash ${globalArgs.nixosConfigPath}/copy-dotfiles/from-repo-to-home.sh && sudo nixos-rebuild switch --flake ${globalArgs.nixosConfigPath}?submodules=1 && home-manager switch -b backup --flake ${globalArgs.nixosConfigPath}?submodules=1 && bash ${globalArgs.nixosConfigPath}/copy-dotfiles/from-repo-to-home.sh";
    nix-prb = "sudo sleep 0 && git-pull-nixconf && nix-rb";
    nix-gc = "nix-collect-garbage -d";
  };
}
