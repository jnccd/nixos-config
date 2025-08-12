{ config, lib, pkgs, globalArgs, ... }:
let nixosConfigPath = "/home/${globalArgs.mainUsername}/git/nixos-config";
in {
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
      "git checkout main && git pull && git submodule foreach 'git checkout main && git pull'";
    git-pull-nixconf =
      "oldPwd=$(pwd) && cd ${nixosConfigPath} && git-pull && cd $oldPwd";

    # Home only rebuild
    nix-hrb =
      "bash ${nixosConfigPath}/copy-dotfiles/from-repo-to-home.sh && home-manager switch -b backup --flake ${nixosConfigPath}?submodules=1 && bash ${nixosConfigPath}/copy-dotfiles/from-repo-to-home.sh";
    # Rebuild
    nix-rb =
      "bash ${nixosConfigPath}/copy-dotfiles/from-repo-to-home.sh && sudo nixos-rebuild switch --flake ${nixosConfigPath}?submodules=1 && home-manager switch -b backup --flake ${nixosConfigPath}?submodules=1 && bash ${nixosConfigPath}/copy-dotfiles/from-repo-to-home.sh";
    # Pull and rebuild
    nix-prb = "sudo sleep 0 && git-pull-nixconf && nix-rb";
    nix-gc = "nix-collect-garbage -d";
    nix-tr = "nix-tree /run/current-system";
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-sz" ''
      nix path-info -rsSh nixpkgs#$1 | awk '{print $1 "\t" $2 $3 "\t" $4 $5 }' | sort -h -k3 | column -t
    '')
    (pkgs.writeShellScriptBin "scrn-kill" ''
      screen -X -S $1 quit
    '')
  ];
}
