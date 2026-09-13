{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
let
  # The nixos-config checkout and the directories on the path down to it.
  # globalArgs.nixosConfigPath is /home/<mainUser>/git/nixos-config, so its two
  # parents are the `git/` directory and the main user's home directory itself.
  # Those three are the `<mainUser>/ git/ nixos-config/` of the option: with the
  # "other" permission bit closed on any of them, another user cannot reach the
  # files inside the checkout no matter how readable those files are.
  repoDir = globalArgs.nixosConfigPath;
  gitDir = dirOf repoDir;
  homeDir = dirOf gitDir;

  # 0755 lets every user read/traverse; 0750 keeps it to the owner's group.
  # The whole difference is the "other" bit, which is what a non-group account
  # (e.g. the sandbox user) needs to reach the readable files in the checkout.
  mode = if config.dobikoConf.openHomeRebuild then "0755" else "0750";

  # Opened recursively: a rebuild reads their contents, not just the directory.
  recursiveTargets = [
    "${repoDir}/.git"
    "${repoDir}/copy-dotfiles"
    "${repoDir}/dotfiles"
    "${repoDir}/hosts"
    "${repoDir}/lib"
    "${repoDir}/modules/homemanager"
  ];

  # The listed files plus the directories on the path to them. Only their OWN
  # mode is changed on purpose: chmod -R on $HOME would also rewrite the modes
  # of .ssh, .gnupg, ... which have to stay private.
  plainTargets = [
    "${repoDir}/flake.nix"
    "${repoDir}/flake.lock"
    "${repoDir}/globalArgs.nix"
    "${repoDir}/modules/"
    repoDir
    gitDir
    homeDir
  ];

  chmodLoop = recursive: targets: ''
    for p in ${lib.concatStringsSep " " (map lib.escapeShellArg targets)}; do
      [ -e "$p" ] || continue
      chmod ${if recursive then "-R " else ""}"$mode" -- "$p"
    done
  '';

  script = pkgs.writeShellScript "open-home-rebuild-script" ''
    mode="${mode}"
    ${chmodLoop true recursiveTargets}
    ${chmodLoop false plainTargets}

    cd ${repoDir}
    git config core.fileMode false

    echo "Done"

    ${lib.custom.bashWaitForever}
  '';
in
{
  options.dobikoConf.openHomeRebuild = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Open the nixos-config checkout, and the directories on the path to it, to
      users outside the main user's group.
    '';
  };

  config = {
    # mkScreenService, not mkWrappedScreenService: the wrapped variant first
    # blocks on `bashEnsureInternet` and then chdirs into ~/screen-runs/<name>,
    # neither of which a local chmod needs. Absolute paths are baked in below,
    # so the working directory is irrelevant.
    systemd.services = lib.custom.mkScreenService {
      sessionName = "open-home-rebuild";
      username = globalArgs.mainUser.name;
      script = script;
    };
  };
}
