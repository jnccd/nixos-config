# sudo nixos-rebuild switch --flake .?submodules=1
# sudo nixos-rebuild switch --install-bootloader --flake .?submodules=1
# nix flake update --flake .?submodules=1
# home-manager switch -b backup --flake .?submodules=1
# nix-collect-garbage -d
# ---
# sudo nixos-rebuild switch --flake .?submodules=1 && home-manager switch -b backup --flake .?submodules=1
# ---
# sops -e -i secrets/
# sops secrets/
# sops updatekeys secrets/
# nix-shell -p ssh-to-age --run 'cat ~/.ssh/id_ed25519.pub | ssh-to-age'
# nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/keys.txt" && sudo mv ~/keys.txt ~/.config/sops/age/keys.txt
# cat ~/.ssh/id_ed25519.pub | ssh dobiko@minis "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
# ---
# git grep "secret" $(git rev-list --all)
# git submodule update --init --recursive
# git submodule update --recursive --remote
# ---
# { config, lib, pkgs, globalArgs, ... }:
{
  description = "Dobiko Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, home-manager, sops-nix, ... }@inputs:
    let
      globalArgs = {
        stateVersion = "24.11";
        homeStateVersion = "24.11";

        mainUsername = "dobiko";
        defaultSystemUsername = "runner";
        githubUsername = "jnccd";
        email = "kobidogao@outlook.com";
      };

      hosts = [
        {
          hostname = "lt-coffeelake";
          system = "x86_64-linux";
        }
        {
          hostname = "pc-ryzen";
          system = "x86_64-linux";
        }
        {
          hostname = "pc-ryzen-vm";
          system = "x86_64-linux";
        }
        {
          hostname = "pc-ryzen-wsl";
          system = "x86_64-linux";
        }
        {
          hostname = "sv-minis";
          system = "x86_64-linux";
        }
      ];

      extendWithCustomLib = system:
        nixpkgs.lib.extend (self: super: {
          custom = import ./lib {
            inherit (nixpkgs) lib;
            pkgs = nixpkgs.legacyPackages.${system};
          };
        });

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
    in {
      nixosConfigurations = builtins.listToAttrs (map mkSystem hosts);
      homeConfigurations = builtins.listToAttrs (map mkHome hosts);
    };
}
