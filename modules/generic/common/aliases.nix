{ config, lib, pkgs, globalArgs, ... }:
let nixosConfigPath = "/home/${globalArgs.mainUser.name}/git/nixos-config";
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
    py-shell = ''
      nix-shell -p python3 virtualenv --command '
        VENV_DIR="/tmp/py-shell-venv-$RANDOM-$RANDOM"
        virtualenv "$VENV_DIR"
        source "$VENV_DIR/bin/activate"
        exec bash'
    '';

    git-pull =
      "git checkout main && git pull && git submodule update --init --recursive && git submodule foreach 'git checkout main && git pull'";
    git-pull-nixconf =
      "oldPwd=$(pwd) && cd ${nixosConfigPath} && git-pull && cd $oldPwd";

    flake-upd = "nix flake update --flake .?submodules=1";

    # Home only rebuild
    nix-cpd = "bash ${nixosConfigPath}/copy-dotfiles/from-repo-to-home.sh";
    nix-hrb =
      "export COPY_DOTFILES_SUDOLESS=true && nix-cpd && home-manager switch -b backup --flake ${nixosConfigPath}?submodules=1 && nix-cpd";
    # Rebuild
    nix-rb =
      "sudo sleep 0 && export COPY_DOTFILES_SUDOLESS= && nix-cpd && sudo nixos-rebuild switch --flake ${nixosConfigPath}?submodules=1 && home-manager switch -b backup --flake ${nixosConfigPath}?submodules=1 && nix-cpd";
    # Pull and rebuild
    nix-prb = "sudo sleep 0 && git-pull-nixconf && nix-rb";
    nix-gc = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
    nix-tr = "nix-tree /run/current-system";

    fix-screen-service-perms = ''
      while IFS=: read -r user _ uid gid _ home shell; do
        if [ -d "$home/screen-runs" ]; then
          echo "$home"
          
          sudo chown -R $uid:$gid "$home/screen-runs"
          sudo chmod -R 750 "$home/screen-runs"
        fi
      done < /etc/passwd
    '';
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-sz" ''
      nix path-info -rsSh nixpkgs#$1 | awk '{print $1 "\t" $2 $3 "\t" $4 $5 }' | sort -h -k3 | column -t
    '') # Get the closure filesize of a installed nix package
    (pkgs.writeShellScriptBin "scrn-kill" ''
      screen -X -S $1 quit
    '') # Kill a screen instance
  ];
}
