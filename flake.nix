# sudo nixos-rebuild switch --flake .?submodules=1
# sudo nixos-rebuild switch --install-bootloader --flake .?submodules=1
# nix flake update --flake .?submodules=1
# home-manager switch -b backup --flake .?submodules=1
# nix-collect-garbage -d
# sops secrets/secrets.yaml
# sops updatekeys secrets.yaml
# nix-shell -p ssh-to-age --run 'cat ~/.ssh/id_ed25519.pub | ssh-to-age'
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

    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs: let
    stateVersion = "24.11";
    homeStateVersion = "24.11";

    mainUsername = "dobiko";

    hosts = [
      { hostname = "lt-coffeelake"; system = "x86_64-linux"; }
    ];

    extendWithCustomLib = system: 
      nixpkgs.lib.extend (self: super: { custom = import ./lib { pkgs = nixpkgs.legacyPackages.${system}; }; });

    mkSystem = host: {
      name = "${host.hostname}";
      value = nixpkgs.lib.nixosSystem {
        inherit (host) system;
        specialArgs = {
          inherit inputs mainUsername stateVersion;
          inherit (host) hostname;
          lib = extendWithCustomLib host.system;
        };

        modules = [
          ./hosts/${host.hostname}/configuration.nix
          sops-nix.nixosModules.sops
        ];
      };
    };

    mkHome = host: {
      name = "${mainUsername}@${host.hostname}";
      value = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${host.system};
        extraSpecialArgs = {
          inherit inputs homeStateVersion mainUsername;
          lib = extendWithCustomLib host.system;
        };

        modules = [
          ./hosts/${host.hostname}/home.nix
        ];
      };
    };
  in {
    nixosConfigurations = builtins.listToAttrs (map mkSystem hosts);
    homeConfigurations = builtins.listToAttrs (map mkHome hosts);
  };
}
