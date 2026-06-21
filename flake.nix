{
  description = "Dobiko Config";

  inputs = {

    # --- Common ---

    # - Core -
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # - WSL -
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- GUI ---

    # - KDE Plasma -
    kwin-effects-better-blur-dx = {
      url = "github:xarblu/kwin-effects-better-blur-dx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # - Grub -
    crossgrub-theme = {
      url = "github:jnccd/crossgrub";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # - Monitoring -
    tux-manager = {
      url = "github:benapetr/TuxManager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # - Instant Eyedropper Reborn -
    instant-eyedropper-r = {
      url = "github:miaupaw/ie-r";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # - CachyOS Kernel -
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };

    # --- Server ---
    working-keycloak-nixpkgs = {
      url = "github:nixos/nixpkgs/8bb5646e0bed5dbd3ab08c7a7cc15b75ab4e1d0f";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      nixos-wsl,
      ...
    }@inputs:
    let
      globalArgs = import ./globalArgs.nix;

      # Load hosts
      hostsDir = ./hosts;
      entries = builtins.readDir hostsDir;
      hostNames = builtins.attrNames (nixpkgs.lib.filterAttrs (name: type: type == "directory") entries);
      hosts = map (hostname: {
        inherit hostname;
        system = builtins.readFile (hostsDir + "/${hostname}/system");
      }) hostNames;

      # Load custom lib
      extendWithCustomLib =
        system:
        nixpkgs.lib.extend (
          self: super: {
            custom = import ./lib {
              inherit (nixpkgs) lib;
              pkgs = nixpkgs.legacyPackages.${system};
            };
          }
        );

      # Define NixOS system config set for a host
      mkSystem = host: {
        name = "${host.hostname}";
        value =
          let
            isWsl = nixpkgs.lib.strings.hasSuffix "-wsl" host.hostname;
          in
          nixpkgs.lib.nixosSystem {
            inherit (host) system;
            specialArgs = {
              inherit inputs globalArgs isWsl;
              inherit (host) hostname;
              inherit (host) system;
              lib = extendWithCustomLib host.system;
            };

            modules = [
              ./hosts/${host.hostname}/configuration.nix
              sops-nix.nixosModules.sops
            ]
            ++ (if isWsl then [ nixos-wsl.nixosModules.default ] else [ ]);
          };
      };

      # Define HomeManager config set for a host
      mkHomes =
        host:
        let
          homeUsers = builtins.filter (x: !x.isSystem) globalArgs.baseUsers;
        in
        map (homeUser: {
          name = "${homeUser.name}@${host.hostname}";
          value = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.${host.system};
            extraSpecialArgs = {
              inherit inputs globalArgs homeUser;
              inherit (host) hostname;
            };

            modules = [ ./hosts/${host.hostname}/home.nix ];
          };
        }) homeUsers;
    in
    {
      nixosConfigurations = builtins.listToAttrs (map mkSystem hosts);
      homeConfigurations = builtins.listToAttrs (builtins.concatMap mkHomes hosts);
    };
}
