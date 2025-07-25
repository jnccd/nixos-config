{
  description = "Dobiko Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, nixos-wsl, nixos-generators
    , ... }@inputs:
    let
      globalArgs = import ./globalArgs.nix;

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
            sops-nix.nixosModules.sops
          ] ++ (if nixpkgs.lib.strings.hasSuffix "-wsl" host.hostname then
            [ nixos-wsl.nixosModules.default ]
          else
            [ ]);
        };
      };

      # Define HomeManager config set for a host
      mkHome = host: {
        name = "${globalArgs.mainUsername}@${host.hostname}";
        value = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${host.system};
          extraSpecialArgs = {
            inherit inputs globalArgs;
            inherit (host) hostname;
          };

          modules = [ ./hosts/${host.hostname}/home.nix ];
        };
      };

      # Define package config set for aws builds (and maybe more in the future)
      awsPackage = let
        system = builtins.readFile ("${hostsDir}/${hostname}/system");
        hostname = "pk-aws";
      in {
        aws = nixos-generators.nixosGenerate {
          inherit system;
          modules = [
            ./hosts/pk-aws/configuration.nix
            sops-nix.nixosModules.sops

          ];

          specialArgs = {
            inherit inputs globalArgs hostname;
            lib = extendWithCustomLib system;
          };
          format = "amazon";
        };
      };
    in {
      nixosConfigurations = builtins.listToAttrs (map mkSystem hosts);
      homeConfigurations = builtins.listToAttrs (map mkHome hosts);

      packages.x86_64-linux = awsPackage;
    };
}
