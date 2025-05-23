# <img src="https://github.com/user-attachments/assets/d46f6ade-c539-47c6-a7a5-b98c7b4e5559" alt="Diagram" height="40" style="vertical-align:middle;"> My NixOS Flake 

<img src="https://github.com/user-attachments/assets/d01d1363-8a59-4cd7-8c2c-b340982a4fc8" alt="Description" width="450ch" height=auto>

Yeah, I destroyed my system completely multiple times while building this. 
But flakes are definitely reproducible which is neat.

## What does it look like?

![Screenshot_20250418_122847](https://github.com/user-attachments/assets/208d8c45-3919-49e6-af4b-a38eb07e7f9b)

Like this 👀

Its basically default Plasma 6 Breeze with some modifications for more transparency because thats fancy. The idea here was to create a good looking DE that (mostly) doesnt break within the next patch, so I didnt go overboard with any of the modifications. 

The background image is from [Alena Aenami](https://www.artstation.com/artwork/n0mwQo). Go check her out, she makes amazing artworks 👀

## Installation

> [!WARNING]
> Since I am always changing the config this is pretty much out of date all the time :)

> [!WARNING]
> Since parts of this config are private youll have to substitute some parts of the config to make it work

1. Use the nixos iso installer to get the basic system
2. `sudo nixos-generate-config`
3. Edit the initial config to get git and add the desired hostname in networking.hostname
4. `sudo nixos-rebuild switch`
5. Reboot
6. [Generate a new ssh key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and register it to your github/gitlab account
7. Clone the nixos-config repo via ssh into `~/git/nixos-config` (yes the path is important)
8. In the flake.nix, add the new host in the hosts array
9. In the hosts folder, add a folder for the given hostname and within it the `hardware-configuration.nix` from the initial config
10. Populate the hostname folder with the configuration.nix and home.nix from another host to init
11. `sudo nixos-rebuild switch --install-bootloader --flake .` <- if your computer just fucking dies during this step you fucked up and have to start from the beginning again :)
12. Reboot for good measure
13. `nix-rb`
14. Log into vivaldi or your favorite browser, sync settings, (maybe try out [my style](https://github.com/jnccd/vivaldi-style))
15. Done, enjoy :)

## Tip

Whenever you change and rebuild a flake, make sure to look at the memory usage of the system. 

You might have assigned a variable at the wrong place and created an infinite tree thats about to fill up your swapfile :)

[Me when memory leek](https://www.reddit.com/r/196/comments/13z6p1x/hatsune_miku_devouring_her_leek/)

## Inspiration

I mainly learned Nix from Ampersand's and Vimjoyer's YouTube videos as well as these repos:

https://github.com/Andrey0189/nixos-config-reborn

https://github.com/EmergentMind/nix-config

https://github.com/Baitinq/nixos-config
