# sudo nixos-rebuild switch --flake .?submodules=1
# sudo nixos-rebuild switch --install-bootloader --flake .?submodules=1
# nix flake update --flake .?submodules=1
# home-manager switch -b backup --flake .?submodules=1
# nix-collect-garbage -d
# ---
# sudo nixos-rebuild switch --flake .?submodules=1 && home-manager switch -b backup --flake .?submodules=1
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
    stateVersion = "24.11";
    homeStateVersion = "24.11";

    hosts = [
      { hostname = "lt-coffeelake"; system = "x86_64-linux"; }
    ];
  in {
    nixosConfigurations = builtins.listToAttrs
      (map (host: {
        name = "${host.hostname}";
        value = nixpkgs.lib.nixosSystem {
          inherit (host) system;
          specialArgs = {
            inherit inputs username stateVersion;
            inherit (host) hostname;
          };

          modules = [
            ./hosts/${host.hostname}/configuration.nix
          ];
        };
      }) hosts);

    homeConfigurations = builtins.listToAttrs
      (map (host: {
        name = "${username}@${host.hostname}";
        value = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${host.system};
          extraSpecialArgs = {
            inherit inputs homeStateVersion username;
          };

          modules = [
            ./hosts/${host.hostname}/home.nix
          ];
        };
      }) hosts);
  };
}
