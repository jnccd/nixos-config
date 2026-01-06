{
  description = "Dobiko Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kwin-effects-forceblur = {
      url = "github:taj-ny/kwin-effects-forceblur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, nixos-wsl, ... }@inputs:
    let
      globalArgs = import "${inputs.self}/globalArgs.nix";

      # Load hosts
      hostsDir = ./hosts;
      entries = builtins.readDir hostsDir;
      hostNames = builtins.attrNames
        (nixpkgs.lib.filterAttrs (name: type: type == "directory") entries);
      hosts = map (hostname: {
        inherit hostname;
        system = builtins.readFile (hostsDir + "/${hostname}/system");
      }) hostNames;

      # Load custom lib
      extendWithCustomLib = system:
        nixpkgs.lib.extend (self: super: {
          custom = import ./lib {
            inherit (nixpkgs) lib;
            pkgs = nixpkgs.legacyPackages.${system};
          };
        });

      # Define HomeManager users for a host
      mkHomes = { host, globalArgs }:
        let homeUsers = builtins.filter (x: !x.isSystem) globalArgs.baseUsers;
        in map (homeUser: {
          name = "${homeUser.name}";
          value = {
            extraModules = [
              (import ./hosts/${host.hostname}/home.nix {
                _args = {
                  inherit inputs globalArgs homeUser;
                  inherit (host) hostname;
                  lib = extendWithCustomLib host.system;
                  pkgs = nixpkgs.legacyPackages.${host.system};
                };

              })
            ];
          };
        }) homeUsers;

      # Define NixOS system config set for a host
      mkSystem = host: {
        name = "${host.hostname}";
        value = nixpkgs.lib.nixosSystem {
          inherit (host) system;
          specialArgs = {
            inherit inputs globalArgs;
            inherit (host) hostname;
            lib = extendWithCustomLib host.system;
          };

          modules = [
            ./hosts/${host.hostname}/configuration.nix
            home-manager.nixosModules.default
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users =
                  builtins.listToAttrs (mkHomes { inherit host globalArgs; });
              };
            }
            sops-nix.nixosModules.sops
          ] ++ (if nixpkgs.lib.strings.hasSuffix "-wsl" host.hostname then
            [ nixos-wsl.nixosModules.default ]
          else
            [ ]);
        };
      };
    in { nixosConfigurations = builtins.listToAttrs (map mkSystem hosts); };
}
