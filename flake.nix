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
    username = "dobiko";
    homeStateVersion = "24.11";

    hosts = [
      { hostname = "lt-coffeelake"; system = "x86_64-linux"; stateVersion = "24.11"; }
      { hostname = "nixos"; system = "x86_64-linux"; stateVersion = "24.11"; }
    ];
  in {
    nixosConfigurations = map (host:
      {
        "${host.hostname}" = nixpkgs.lib.nixosSystem {
          inherit (host) system;
          specialArgs = {
            inherit inputs username;
            inherit (host) hostname stateVersion;
          };

          modules = [
            ./hosts/${host.hostname}/configuration.nix
          ];
        };
      }) hosts;

    homeConfigurations = map (host:
      {
        "${username}@${host.hostname}" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${host.system};
          extraSpecialArgs = {
            inherit inputs homeStateVersion username;
          };

          modules = [
            ./hosts/${host.hostname}/home.nix
          ];
        };
      }) hosts;
  };
}
