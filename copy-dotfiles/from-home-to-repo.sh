#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

mk_and_cp() {
    mkdir -p $(dirname $2)
    cp --dereference $1 $2
}
mk_and_cpr() {
    mkdir -p $2
    cp --dereference -r $1 $(dirname $2)
}

cp_to_dotfiles() {
    mk_and_cp ~/$1 "../dotfiles/$1"
}
cpr_to_dotfiles() {
    mk_and_cpr ~/$1 "../dotfiles/$1"
    find ../dotfiles/ -name "*.backup" -type f -delete
}

# KDE Plasma 6
# based on: https://github.com/shalva97/kde-configuration-files
cp_to_dotfiles .config/plasma-org.kde.plasma.desktop-appletsrc
cp_to_dotfiles .config/kdeglobals
cp_to_dotfiles .config/kscreenlockerrc
cp_to_dotfiles .config/kwinrc
cp_to_dotfiles .config/gtkrc
cp_to_dotfiles .config/gtkrc-2.0
cpr_to_dotfiles .config/gtk-4.0/
cpr_to_dotfiles .config/gtk-3.0/
cp_to_dotfiles .config/ksplashrc
cp_to_dotfiles .config/kdeglobals
cp_to_dotfiles .config/plasmarc
cp_to_dotfiles .config/kdeglobals
cp_to_dotfiles .config/Trolltech.conf
cp_to_dotfiles .config/breezerc
cp_to_dotfiles .config/kdeglobals
cp_to_dotfiles .config/kcmfonts
cp_to_dotfiles .config/kdeglobals
cp_to_dotfiles .config/kcminputrc
cp_to_dotfiles .config/klaunchrc
cp_to_dotfiles .config/kfontinstuirc
cp_to_dotfiles .config/ksplashrc
cp_to_dotfiles .config/plasmarc
cp_to_dotfiles .config/kglobalshortcutsrc
cp_to_dotfiles .config/kscreenlockerrc
cp_to_dotfiles .config/kactivitymanagerdrc
cp_to_dotfiles .config/kactivitymanagerd-switcher
cp_to_dotfiles .config/kactivitymanagerd-statsrc
cp_to_dotfiles .config/kactivitymanagerd-pluginsrc
cp_to_dotfiles .config/plasma-org.kde.plasma.desktop-appletsrc
cp_to_dotfiles .config/kwinrulesrc
cp_to_dotfiles .config/khotkeysrc
cp_to_dotfiles .config/kded5rc
cp_to_dotfiles .config/ksmserverrc
cp_to_dotfiles .config/krunnerrc
cp_to_dotfiles .config/baloofilerc
cp_to_dotfiles .config/kuriikwsfiltersrc
cpr_to_dotfiles .local/share/kservices5/searchproviders/
cpr_to_dotfiles .local/share/plasma-systemmonitor/
cp_to_dotfiles .config/plasmanotifyrc
cp_to_dotfiles .config/plasma-localerc
cp_to_dotfiles .config/plasma-localerc
cp_to_dotfiles .config/ktimezonedrc
cp_to_dotfiles .config/kaccessrc
cp_to_dotfiles .config/mimeapps.list
cp_to_dotfiles .config/user-dirs.dirs
cp_to_dotfiles .local/share/user-places.xbel
cp_to_dotfiles .config/mimeapps.list
cp_to_dotfiles .config/PlasmaUserFeedback
cp_to_dotfiles .config/kcminputrc
cp_to_dotfiles .config/touchpadxlibinputrc
cp_to_dotfiles .config/kgammarc
cp_to_dotfiles .config/powermanagementprofilesrc
cp_to_dotfiles .config/bluedevilglobalrc
cp_to_dotfiles .config/kdeconnect
cp_to_dotfiles .config/device_automounter_kcmrc
cp_to_dotfiles .config/kded_device_automounterrc
cp_to_dotfiles .config/arkrc
cp_to_dotfiles .config/dolphinrc
cp_to_dotfiles .config/filelightrc
cp_to_dotfiles .config/dolphinrc
cp_to_dotfiles .config/katerc
cp_to_dotfiles .config/katevirc
cp_to_dotfiles .config/kate-externaltoolspluginrc
cp_to_dotfiles .config/kcalcrc
cp_to_dotfiles .config/partitionmanagerrc
cp_to_dotfiles .config/konsolesshconfig
cp_to_dotfiles .config/krusaderrc
cp_to_dotfiles .config/spectaclerc
cp_to_dotfiles .config/systemmonitorrc
cp_to_dotfiles .config/systemsettingsrc
cp_to_dotfiles .config/plasmaparc

# Konsole
cp_to_dotfiles .config/konsolerc
cpr_to_dotfiles .local/share/konsole/
cp_to_dotfiles .local/state/konsolestaterc

# XFCE
cp_to_dotfiles .config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
cp_to_dotfiles .config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
cp_to_dotfiles .config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
cp_to_dotfiles .config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

cp_to_dotfiles .local/share/kio/servicemenus/openVSCode.desktop

cp_to_dotfiles .nanorc

cpr_to_dotfiles .config/nvim/

cp_to_dotfiles .config/Code/User/settings.json
cpr_to_dotfiles .config/Code/User/profiles/
cp_to_dotfiles .config/Code/Preferences

cp_to_dotfiles .config/nushell/config.nu
cp_to_dotfiles .config/nushell/env.nu