# sudo nixos-rebuild switch --flake .
# sudo nixos-rebuild switch --install-bootloader --flake .
# nix flake update --flake /home/dobiko/nix
{
  description = "Dobiko Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let
    user = "dobiko";
    homeStateVersion = "24.11";
    defaultSystem = "x86_64-linux";

    hosts = [
      { hostname = "lt-coffeelake"; system = "x86_64-linux"; stateVersion = "24.11"; }
    ];

    mkSystem = { hostname, system, stateVersion, homeStateVersion, user }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs stateVersion hostname user;
      };

      modules = [
        ./hosts/${hostname}/configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit inputs hostname homeStateVersion user;
          };
          home-manager.users.${user} = {...}: {
            imports = [
              ./hosts/${hostname}/home.nix
            ];
          };
        }
      ];
    };
  in {
    nixosConfigurations = nixpkgs.lib.foldl' (configs: host:
      configs // {
        "${host.hostname}" = mkSystem {
          inherit (host) hostname system stateVersion;
          inherit homeStateVersion;
          inherit user;
        };
      }) {} hosts;

    # homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
    #   pkgs = nixpkgs.legacyPackages.${defaultSystem};
    #   extraSpecialArgs = {
    #     inherit inputs homeStateVersion user;
    #   };

    #   modules = [
    #     ./home-manager/home.nix
    #   ];
    # };
  };
}