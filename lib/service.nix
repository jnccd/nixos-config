{ pkgs, lib }:
rec {
  bashEnsureInternet = "until host www.google.de; do sleep 30; done";
  bashWaitForever = "while :; do sleep 2073600; done";
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
  mkGuiAutostartService =
    {
      serviceName,
      username,
      guiScript,
    }:
    mkWrappedScreenService rec {
      sessionName = serviceName;
      inherit username;
      scriptDirName = sessionName;
      wantedBy = [ "graphical.target" ];
      requires = [ "graphical.target" ];
      after = [ "graphical.target" ];
      script = pkgs.writeScript "script" ''
        sleep 1
        ${bashGetUserEnvVars username}
        ${guiScript}
      '';
    };
  mkGuiAppService =
    {
      username,
      repoName,
      repoUrl,
      defineEnvVarsScript ? "",
    }:
    mkGuiAutostartService rec {
      serviceName = "${repoName}-starter";
      inherit username;
      guiScript = pkgs.writeScript "script" ''
        REPO_CHANGED=0

        # Clone if possible
        (git clone ${repoUrl} "./${repoName}" && REPO_CHANGED=1) || true
        # Pull if necessary
        OLD_REV=$(git -C "./${repoName}" rev-parse HEAD 2>/dev/null || echo "")
        ${scriptForceRefreshGitRepo "./${repoName}"}
        NEW_REV=$(git -C "./${repoName}" rev-parse HEAD 2>/dev/null || echo "")
        [ "$OLD_REV" != "$NEW_REV" ] && REPO_CHANGED=1

        while true; do
          ${bashGetUserEnvVars username}
          ${defineEnvVarsScript}

          [ "$REPO_CHANGED" -eq 0 ] && export NIXOS_JNCCD_GUI_STARTER_UNCHANGED=1
          [ "$REPO_CHANGED" -ne 0 ] && unset NIXOS_JNCCD_GUI_STARTER_UNCHANGED

          mkdir -p ~/.nix-profiles
          nix develop --profile ~/.nix-profiles/${serviceName} ./${repoName}#desktop -c bash ${pkgs.writeScript "script" ''
            cd ${repoName}
            bash start_desktop_app.sh
          ''}
          
          REPO_CHANGED=0
          OLD_REV=$(git -C "./${repoName}" rev-parse HEAD 2>/dev/null || echo "")
          ${scriptForceRefreshGitRepo "./${repoName}"}
          NEW_REV=$(git -C "./${repoName}" rev-parse HEAD 2>/dev/null || echo "")
          [ "$OLD_REV" != "$NEW_REV" ] && REPO_CHANGED=1
        done
      '';
    };

  mkOnTagUpdatingGitBasedService =
    {
      serviceName,
      repoName,
      repoUrl,
      serviceUser,
      defineEnvVarsScript,
    }:
    mkWrappedScreenService {
      sessionName = serviceName;
      username = serviceUser;
      scriptDirName = serviceName;
      script = pkgs.writeScript "script" ''
        git clone ${repoUrl} || true
        ${scriptForceRefreshGitRepo "./${repoName}"}

        ${defineEnvVarsScript}

        while true; do
          nix develop ./${repoName}#service -c bash ${pkgs.writeScript "script" ''
            cd ${repoName}
            bash start_service.sh
          ''}
          
          ${scriptForceRefreshGitRepo "./${repoName}"}
        done
      '';
    }
    // mkWrappedScreenService {
      sessionName = "${serviceName}-updater";
      username = serviceUser;
      scriptDirName = "${serviceName}-updater";
      script = pkgs.writeScript "script" ''
        sleep 60
        cd ../${serviceName}/${repoName}

        while true; do
          (git reset --hard && git fetch --tags) || (echo "Error fetching updates!" && sleep 120 && continue)

          LOCAL_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
          REMOTE_TAG=$(git describe --tags --abbrev=0 origin 2>/dev/null)

          if [ "$LOCAL_TAG" != "$REMOTE_TAG" ]; then
            echo "Local $LOCAL_TAG / Remote $REMOTE_TAG"
            echo "$(date): New tag(s) available. Sending Ctrl-C to ${serviceName}."
            screen -S "${serviceName}" -X stuff $'\003'
          else
            echo "$(date): No new tag(s)."
          fi

          sleep 120
        done
      '';
    };
  mkUpdatingContainerService =
    {
      screenSessionName,
      serviceName,
      imageName,
      serviceUser,
      defineEnvVarsScript,
      envVarsToPass,
    }:
    mkWrappedScreenService {
      sessionName = screenSessionName;
      username = serviceUser;
      scriptDirName = serviceName;
      script = pkgs.writeScript "script" ''
        ${defineEnvVarsScript}
        while true; do
          docker pull ${imageName}
          docker run -i --restart=always ${
            builtins.concatStringsSep " " (
              lib.concatMap (x: [
                "-e"
                x
              ]) envVarsToPass
            )
          } --replace --name ${serviceName} ${imageName}
        done
      '';
      cleanupScript = ''
        docker stop ${serviceName} || true
        docker rm ${serviceName} || true
      '';
    }
    // mkWrappedScreenService {
      sessionName = "${screenSessionName}-updater";
      username = serviceUser;
      scriptDirName = "${serviceName}-updater";
      script = pkgs.writeScript "script" ''
        old_digest=$(docker inspect --format='{{index .RepoDigests 0}}' ${imageName} 2>/dev/null || echo "")
        while true; do
          docker pull ${imageName} || (echo "Error fetching updates!" && sleep 120 && continue)
          new_digest=$(docker inspect --format='{{index .RepoDigests 0}}' ${imageName})

          if [ "$old_digest" != "$new_digest" ]; then
              echo "New image version detected: $new_digest"
              screen -S ${screenSessionName} -X stuff $'\003'
              old_digest=$new_digest
          else
              echo "No update found."
          fi
          sleep 120
        done
      '';
    };
  mkOnCommitUpdatingNodeWebsiteModule =
    {
      websiteName,
      websiteUrl,
      repoName,
      repoUrl,
      serviceUser,
      buildServiceName,
      firewallPorts,
      isNginxDefault ? false,
    }:
    {
      # - Firewall -
      networking.firewall.allowedTCPPorts = firewallPorts;

      # - Nginx -
      services.nginx = {
        enable = true;

        # Certs go here: /var/lib/acme/[domain]/
        virtualHosts."${websiteUrl}" = {
          default = isNginxDefault;
          addSSL = true;
          enableACME = true;
          root = "/etc/www/${websiteName}/";
        };
      };

      # - Service -
      systemd.services =
        mkWrappedScreenService {
          sessionName = buildServiceName;
          username = serviceUser;
          scriptDirName = buildServiceName;
          script = pkgs.writeScript "website-build-script" ''
            build_site() {
              echo "Rebuilding site..."
              nix develop .#service -c bash -c "npm run build"
              rm -r /etc/www/${websiteName}/*
              cp -r dist/* /etc/www/${websiteName}/
            }

            echo "Startup..."
            git clone ${repoUrl} || echo "Using existing repo"
            cd ${repoName}

            git fetch origin
            if [ $(git rev-list HEAD...origin/main --count) -gt 0 ]; then # This assumes that the default branch is main which is kinda shit but whatever
              echo "Found new commits."
              git pull
              build_site
            else
              echo "No new commits on the remote branch."
            fi

            while true; do
              read -p "Press enter to rebuild"
              git pull

              build_site
            done
          '';
        }
        // mkWrappedScreenService {
          sessionName = "build-${websiteName}-trigger";
          username = serviceUser;
          scriptDirName = "build-${websiteName}-trigger";
          script = pkgs.writeScript "script" ''
            sleep 60
            cd ../${buildServiceName}/${repoName}

            while true; do
              (git reset --hard && git fetch) || (echo "Error fetching updates!" && sleep 120 && continue)

              LOCAL=$(git rev-parse @)
              REMOTE=$(git rev-parse @{u})
              BASE=$(git merge-base @ @{u})

              if [ "$LOCAL" = "$BASE" ] && [ "$REMOTE" != "$BASE" ]; then
                echo "Base $BASE / Local $LOCAL / Remote $REMOTE"
                echo "$(date): New commit(s) available. Sending enter to ${buildServiceName}."
                screen -S "${buildServiceName}" -X stuff $'\n'
              else
                echo "$(date): No new commit(s)."
              fi

              sleep 120
            done
          '';
        };
      environment.etc."www/${websiteName}/.mkdir" = {
        text = "create";
      };
      systemd.tmpfiles.rules = [ "d /etc/www/${websiteName}/ 0770 ${serviceUser} nginx" ];
    };
  mkNasMountService =
    {
      shareFolderName,
      remoteServerName,
      remoteUser,
      remotePassFile,
      localMountUser,
    }:
    let
      mountPoint = "/mnt/nas/${shareFolderName}";
      remoteShare = "//${remoteServerName}/${shareFolderName}";
    in
    mkWrappedScreenService rec {
      sessionName = "mount-nas-${shareFolderName}";
      username = "root";
      scriptDirName = "${sessionName}";
      script = pkgs.writeScript "script" ''
        echo ${remoteShare}
        sudo mkdir -p ${mountPoint}
        sudo mount -t cifs ${remoteShare} ${mountPoint} -o username=${remoteUser},password=$(cat ${remotePassFile}),uid=$(id ${localMountUser} -u),gid=$(id ${localMountUser} -g),dir_mode=0770,file_mode=0660
      '';
      cleanupScript = pkgs.writeScript "cleanup-script" "sudo umount ${mountPoint}";
    };
  mkNasMountModule =
    {
      inputs,
      lib,
      config,
      globalArgs,
      folderName,
      secretsFile,
      mountUser,
    }:
    {
      sops.secrets."nas/${folderName}/user" = {
        sopsFile = "${inputs.self}/secrets/${secretsFile}";
        owner = "root";
      };
      sops.secrets."nas/${folderName}/pass" = {
        sopsFile = "${inputs.self}/secrets/${secretsFile}";
        owner = "root";
      };
      sops.secrets."nas/${folderName}/serverName" = {
        sopsFile = "${inputs.self}/secrets/${secretsFile}";
        owner = "root";
      };

      environment.systemPackages = with pkgs; [ cifs-utils ];

      systemd.services = lib.custom.mkNasMountService {
        shareFolderName = "${folderName}";
        remoteServerName = "$(cat ${config.sops.secrets."nas/${folderName}/serverName".path})";
        remoteUser = "$(cat ${config.sops.secrets."nas/${folderName}/user".path})";
        remotePassFile = config.sops.secrets."nas/${folderName}/pass".path;
        localMountUser = mountUser;
      };
    };
}
