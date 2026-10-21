{ pkgs, lib, ... }:
rec {
  bashEnsureInternet = "until host www.google.de; do sleep 30; done";
  bashWaitForever = "while :; do sleep 2073600; done";
  # Reconstruct a user's session environment for a *system* service that has to
  # reach into their session (e.g. bedtime.nix's kdialog warning, which runs
  # from a system timer as the main user). GUI autostart deliberately does NOT
  # use this any more: a .desktop launched by KDE already has the real session
  # environment, so nothing needs reconstructing.
  bashGetUserEnvVars =
    username:
    "export USER=${username} XDG_RUNTIME_DIR=/run/user/$(id -u ${username}) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u ${username})/bus && eval $(systemctl --user show-environment | xargs -0 -I {} echo export {})";
  systemdExecWrapper =
    script:
    pkgs.writeScript "systemdExecWrapper-script" ''
      #!${pkgs.runtimeShell}
      PATH=$PATH:/run/current-system/sw/bin
      ${script}
    '';
  scriptForceRefreshGitRepo =
    repoPath:
    pkgs.writeScript "for-refresh-git-repo-script" ''
      git -C ${repoPath} reset --hard
      git -C ${repoPath} pull
      git -C ${repoPath} submodule update --init --recursive --force # Dont update --recursive --remote, keep linked versions
    '';

  mkScreenService =
    {
      sessionName,
      username,
      script,
      wantedBy ? [ "multi-user.target" ],
      requires ? [ ],
      after ? [ ],
      cleanupScript ? "",
      extraServiceConfig ? { },
    }:
    {
      "${sessionName}" = {
        enable = true;
        description = sessionName;

        wantedBy = wantedBy;
        requires = requires;
        after = after;

        environment = {
          NIX_PATH = "nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels";
        };

        serviceConfig = {
          User = username;

          ExecStart = systemdExecWrapper ''
            screen -S ${sessionName} -dm bash -c "${script}";
            ${bashWaitForever}
          '';
          ExecStop = systemdExecWrapper ''
            ${cleanupScript}
            screen -XS ${sessionName} quit
          '';
        }
        // extraServiceConfig;
      };
    };
  mkWrappedScreenService =
    {
      sessionName,
      username,
      scriptDirName,
      script,
      wantedBy ? [ "multi-user.target" ],
      requires ? [ "network-online.target" ],
      after ? [ ],
      cleanupScript ? "",
      extraServiceConfig ? { },
    }:
    mkScreenService {
      inherit
        sessionName
        username
        wantedBy
        requires
        after
        extraServiceConfig
        ;
      script = pkgs.writeScript "wrapped-service-script" ''
        ${bashEnsureInternet}
        cd ~ && mkdir -m 750 -p screen-runs/${scriptDirName}; cd screen-runs/${scriptDirName};
        clear
        date
        pwd

        ${script}

        ${bashWaitForever}
      '';
    };
}
