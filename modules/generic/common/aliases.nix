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
    py-shell =
      "nix-shell -p python3 virtualenv --command '[ -d /tmp/py-shell-venv ] || virtualenv /tmp/py-shell-venv; source /tmp/py-shell-venv/bin/activate; exec bash' ";

    git-pull =
      "git checkout main && git pull && git submodule update --init --recursive && git submodule foreach 'git checkout main && git pull'";
    git-pull-nixconf =
      "oldPwd=$(pwd) && cd ${nixosConfigPath} && git-pull && cd $oldPwd";

    flake-upd = "nix flake update --flake .?submodules=1";

    # Home only rebuild
    nix-cpd = "bash ${nixosConfigPath}/copy-dotfiles/from-repo-to-home.sh";
    nix-hrb =
      "nix-cpd && home-manager switch -b backup --flake ${nixosConfigPath}?submodules=1 && nix-cpd";
    # Rebuild
    nix-rb =
      "nix-cpd && sudo nixos-rebuild switch --flake ${nixosConfigPath}?submodules=1 && home-manager switch -b backup --flake ${nixosConfigPath}?submodules=1 && nix-cpd";
    # Pull and rebuild
    nix-prb = "sudo sleep 0 && git-pull-nixconf && nix-rb";
    nix-gc = "nix-collect-garbage -d";
    nix-tr = "nix-tree /run/current-system";
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
