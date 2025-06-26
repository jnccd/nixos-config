#!/bin/sh
if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
    swww init
    swww img ~/Pictures/wallpaper.jpg &
    waybar &
    rofi -show drun &
fi