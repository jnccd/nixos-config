exit 0 # Dont execute this

# Standard Nix Header
#{ inputs, config, lib, pkgs, globalArgs, ... }: {

nix repl --expr 'with import <nixpkgs> {}; pkgs'

sudo nixos-rebuild switch --flake .?submodules=1
sudo nixos-rebuild switch --install-bootloader --flake .?submodules=1
home-manager switch -b backup --flake .?submodules=1
nix-collect-garbage -d

nix flake update --flake .?submodules=1
nix flake update nixpkgs --override-input nixpkgs github:NixOS/nixpkgs/ce01daebf8489ba97bd1609d185ea276efdeb121 && git commit -am "Update flake" && git push

sudo nixos-rebuild switch --flake .?submodules=1 && home-manager switch -b backup --flake .?submodules=1

sops -e -i secrets/
sops secrets/
sops updatekeys secrets/
nix-shell -p ssh-to-age --run 'cat ~/.ssh/id_ed25519.pub | ssh-to-age'
nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/keys.txt" && sudo mv ~/keys.txt ~/.config/sops/age/keys.txt
cat ~/.ssh/id_ed25519.pub | ssh dobiko@minis "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

git grep "secret" $(git rev-list --all)
git submodule update --init --recursive
git submodule update --recursive --remote

nix build .?submodules=1#aws
