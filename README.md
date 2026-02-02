# <img src="https://github.com/user-attachments/assets/d46f6ade-c539-47c6-a7a5-b98c7b4e5559" alt="Diagram" height="40em" style="vertical-align:middle;"> My NixOS Flake

## What does it look like?

![image](https://github.com/user-attachments/assets/7dbbe417-5878-45d9-be5f-b9e11d94240a)

Like this 👀

Its basically default Plasma 6 Breeze with some light modifications. The idea here was to create a good looking DE that (mostly) doesnt break within the next patch, so I didnt go overboard with any of the modifications.

The background image is from [Alena Aenami](https://www.artstation.com/artwork/n0mwQo). Go check her out, she makes amazing artworks 👀

## Installation

> [!WARNING]
> Since parts of this config are private you`ll have to substitute some imports in the config to make it work. Notably, the dotfiles also reference my main username.

1. Use the nixos iso installer to get the basic system
2. `sudo nixos-generate-config`
3. Edit the initial config to get git and add the desired hostname in networking.hostname
4. `sudo nixos-rebuild switch`
5. Reboot
6. [Generate a new ssh key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and register it to your github/gitlab account
7. Clone the nixos-config repo via ssh into `~/git/nixos-config` (yes the path is important)
8. In the hosts folder, add a folder for the given hostname and within it the `hardware-configuration.nix` from the initial config
9. Populate the hostname folder with `system`, `configuration.nix` and `home.nix` files from another host and adapt them as necessary
10. `sudo nixos-rebuild switch --install-bootloader --flake .`
11. Reboot for good measure
12. `nix-rb`
13. Log into vivaldi or your favorite browser, sync settings, (maybe try out [my style](https://github.com/jnccd/vivaldi-style))
14. Done, enjoy :)

## Rebuilding the bootloader

Should a third party (usually windows) destroy your bootloader, then Nixos makes it fairly simle to restore it.
1. Boot into a NixOS installer USB Stick
2. `sudo mount /dev/<your-root-partition> /mnt`

   `sudo mount /dev/<your-broken-boot-partition> /mnt/boot`
3. `sudo nixos-enter`
4. `sudo nixos-rebuild switch --flake /home/<your-user-name>/git/nixos-config?submodules=1#<your-host-name> --install-bootloader`
5. Done, it should boot as normal

If you want to build the bootloader into a new partition, dont forget to update the uuid in `hardware-configuration.nix`.

## Updating

1. Prepare
   1. Update Postgres version {X-1} to {X} if the default version changed in nixpkgs and the state version should be updated
      1. Make sure /var/lib/postgresql/{X} is empty or nonexistant and /var/lib/postgresql/{X-1} has data
         - In some instances (basically all the time) it is wise to disable extensions for the upgrade process and reenable them afterwards (`DROP EXTENSION IF EXISTS <EXTENSION>;`)
      2. In `postgres.nix`, change `services.postgresql.package` to version {X}
      3. `nix-rb`
      4. `systemctl stop postgresql`
      5. `sudo rm -r /var/lib/postgresql/{X}`
      5. `sudo -u postgres initdb -D /var/lib/postgresql/{X}`
      6. `sudo -u postgres pg_upgrade -b "$(nix build --no-link --print-out-paths nixpkgs#postgresql_{X-1}.out)/bin" -B /run/current-system/sw/bin -d /var/lib/postgresql/{X-1} -D /var/lib/postgresql/{X}`
         - If checksums are an issue: `pg_checksums -d /var/lib/postgresql/{X}`
      7. `nix-rb`
   2. Check for other packages that use the state version
2. Update
   1. Update `flake.nix` inputs to new version
   2. Update state version in `globalArgs.nix` to new version (this is not mandatory)
   3. `nix-rb`

## Inspiration

I mainly learned Nix from [Ampersand's](https://www.youtube.com/watch?v=nLwbNhSxLd4) and [Vimjoyer's](https://www.youtube.com/@vimjoyer) YouTube videos as well as these repos:

https://github.com/Andrey0189/nixos-config-reborn

https://github.com/EmergentMind/nix-config

https://github.com/Baitinq/nixos-config
