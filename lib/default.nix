{ pkgs, lib, ... }: rec {
  bashEnsureInternet = "until host www.google.de; do sleep 30; done";
  bashWaitForever = "while :; do sleep 2073600; done";

  mkScreenService = { sessionName, username, script
    , wantedBy ? [ "multi-user.target" ], requires ? [ ], after ? [ ] }: {
      "${sessionName}" = {
        enable = true;
        description = sessionName;

        wantedBy = wantedBy;
        requires = requires;
        after = after;

        environment = {
          NIX_PATH =
            "nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels";
        };

        serviceConfig = {
          User = username;

          ExecStart = pkgs.writeScript "${sessionName}-start-script" ''
            #!${pkgs.runtimeShell}
            PATH=$PATH:/run/current-system/sw/bin
            screen -S ${sessionName} -dm bash -c "${script}";
            ${bashWaitForever}
          '';
          ExecStop = pkgs.writeScript "${sessionName}-stop-script" ''
            #!${pkgs.runtimeShell}
            PATH=$PATH:/run/current-system/sw/bin
            screen -XS ${sessionName} quit
          '';
        };
      };
    };
  mkWrappedScreenService = { sessionName, username, scriptDirName, script
    , wantedBy ? [ "multi-user.target" ], requires ? [ "network-online.target" ]
    , after ? [ ] }:
    mkScreenService {
      inherit sessionName username wantedBy requires after;
      script = pkgs.writeScript "wrapped-service-script" ''
        ${bashEnsureInternet}
        cd ~ && mkdir -p screen-runs/${scriptDirName}; cd screen-runs/${scriptDirName};
        clear
        date
        pwd

        ${script}

        ${bashWaitForever}
      '';
    };
  mkUpdatingGitBasedService =
    { serviceName, repoName, repoUrl, serviceUser, defineEnvVarsScript }:
    mkWrappedScreenService {
      sessionName = serviceName;
      username = serviceUser;
      scriptDirName = serviceName;
      script = pkgs.writeScript "script" ''
        git clone ${repoUrl}
        git -C ./${repoName} pull

        ${defineEnvVarsScript}

        while true; do
          nix develop ./${repoName} -c bash ${repoName}/start_service.sh
          
          git -C ./${repoName} pull
        done
      '';
    } // mkWrappedScreenService {
      sessionName = "${serviceName}-updater";
      username = serviceUser;
      scriptDirName = "${serviceName}-updater";
      script = pkgs.writeScript "script" ''
        sleep 60
        cd ../${serviceName}/${repoName}

        while true; do
          git fetch || (echo "Error fetching updates!" && sleep 120 && continue)

          LOCAL=$(git rev-parse @)
          REMOTE=$(git rev-parse @{u})
          BASE=$(git merge-base @ @{u})

          if [ "$LOCAL" = "$BASE" ] && [ "$REMOTE" != "$BASE" ]; then
            echo "Base $BASE / Local $LOCAL / Remote $REMOTE"
            echo "$(date): New commits available. Sending Ctrl-C to ${serviceName}."
            screen -S "${serviceName}" -X stuff $'\003'
          else
            echo "$(date): No new commits."
          fi

          sleep 120
        done
      '';
    };
  mkUpdatingContainerService = { screenSessionName, serviceName, imageName
    , serviceUser, defineEnvVarsScript, envVarsToPass, }:
    mkWrappedScreenService {
      sessionName = screenSessionName;
      username = serviceUser;
      scriptDirName = serviceName;
      script = pkgs.writeScript "script" ''
        ${defineEnvVarsScript}
        while true; do
          docker pull ${imageName}
          docker run -i --restart=always ${
            builtins.concatStringsSep " "
            (lib.concatMap (x: [ "-e" x ]) envVarsToPass)
          } --replace --name ${serviceName} ${imageName}
        done
      '';
    } // mkWrappedScreenService {
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
  mkUpdatingNodeWebsiteModule = { websiteName, websiteUrl, repoName, repoUrl
    , serviceUser, buildServiceName, firewallPorts, }: {
      # - Firewall -
      networking.firewall.allowedTCPPorts = firewallPorts;

      # - Nginx -
      services.nginx = {
        enable = true;

        # Certs go here: /var/lib/acme/[domain]/
        virtualHosts."${websiteUrl}" = {
          default = true;
          addSSL = true;
          enableACME = true;
          root = "/etc/www/${websiteName}/";
        };
      };

      # - Service -
      systemd.services = lib.custom.mkWrappedScreenService {
        sessionName = buildServiceName;
        username = serviceUser;
        scriptDirName = buildServiceName;
        script = pkgs.writeScript "website-build-script" ''
          git clone ${repoUrl}
          cd ${repoName}
          git pull

          while true; do
            nix develop -c bash -c "npm run build"
            rm -r /etc/www/${websiteName}/*
            cp -r dist/* /etc/www/${websiteName}/
            pwd
            
            read -p "Press enter to rebuild"
            git pull
          done
        '';
      } // lib.custom.mkWrappedScreenService {
        sessionName = "build-${websiteName}-trigger";
        username = serviceUser;
        scriptDirName = "build-${websiteName}-trigger";
        script = pkgs.writeScript "script" ''
          sleep 60
          cd ../${buildServiceName}/${repoName}

          while true; do
            git fetch || (echo "Error fetching updates!" && sleep 120 && continue)

            LOCAL=$(git rev-parse @)
            REMOTE=$(git rev-parse @{u})
            BASE=$(git merge-base @ @{u})

            if [ "$LOCAL" = "$BASE" ] && [ "$REMOTE" != "$BASE" ]; then
              echo "Base $BASE / Local $LOCAL / Remote $REMOTE"
              echo "$(date): New commits available. Sending enter to ${buildServiceName}."
              screen -S "${buildServiceName}" -X stuff $'\n'
            else
              echo "$(date): No new commits."
            fi

            sleep 120
          done
        '';
      };
      environment.etc."www/${websiteName}/.mkdir" = { text = "create"; };
      systemd.tmpfiles.rules =
        [ "d /etc/www/${websiteName}/ 0770 ${serviceUser} nginx" ];
    };

  listAllLocalImportables = path:
    builtins.map (f: (path + "/${f}")) (builtins.attrNames
      (lib.attrsets.filterAttrs (path: _type:
        (_type == "directory") # include directories
        || ((path != "default.nix") # ignore default.nix
          && (lib.strings.hasSuffix ".nix" path) # include .nix files
        )) (builtins.readDir path)));
}
