#!/bin/sh

# Script Name: copy_etc_configs.sh
# Script Path: <git_root>/copy_etc_configs.sh
# Description: Copy etc configuration files.

# Copyright (c) 2024 Aryan
# SPDX-License-Identifier: BSD-3-Clause

# Version: 2.0.0

# Colors
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# Exit if the user is root.
if [ "$(id -u)" -eq 0 ]; then
    if [ -e "/usr/bin/uu-basename" ]; then
        echo "${red}$(uu-basename ${0}): please do not run as root.${nc}"
    else
        echo "${red}$(basename ${0}): please do not run as root.${nc}"
    fi

    exit 1
fi

system="${1}"

if [ -z "${system}" ]; then
    echo "${red}Invalid Option: ${1}${nc}"
    echo "Correct usage: ${0} [SYSTEM]"

    exit 1
fi

# Check if system is reachable.
echo "Checking if ${system} is pingable..."
ping -c 1 -W 1 "${system}" > /dev/null 2>&1 && echo "${green}Success!${nc}" || { echo "${red}${system} is not reachable.${nc}"; exit 1; }

# Check if we can access system via SSH.
echo "Checking if we can obtain ${system}'s via SSH..."
mkdir "./${system}/"
rsync -ahuq "${system}:/etc/hostname" "./${system}/" && echo "${green}Success!${nc}" || { echo "${red}Cannot connect to ${system} via SSH.${nc}"; exit 1; }

# Check if /etc/hostname has the same value as ${system}.
echo "Checking if the hostname on ${system} is ${system}."
hostname=$(cat "./${system}/hostname")
if [ "${hostname}" = "${system}" ]; then
    echo "${green}/etc/hostname file for ${system} says ${system}!${nc}"
else
    echo "${red}/etc/hostname file on ${system} does not match ${system}.${nc}"
    echo "${red}This could be because incorrect hosts configuration on your current system.${nc}"

    rm -r "./${system}/"

    exit 1
fi

echo "${green}Copying over configuration files...${nc}"

# Chrony
mkdir -p "./${system}/chrony/"
rsync -ahuq "${system}:/etc/chrony/chrony.conf" "./${system}/chrony/" || { echo "${red}Error copying over chrony configuration file.${nc}"; exit 1; }

# Explicitly loaded modules
mkdir -p "./${system}/modules-load.d/"
rsync -ahuq "${system}:/etc/modules-load.d/netfilter.conf" "./${system}/modules-load.d/" || { echo "${red}Error copying over modules-load.d configuration files.${nc}"; exit 1; }

# MPV

## Basic
mkdir -p "./${system}/mpv/"
rsync -ahuq "${system}:/etc/mpv/input.conf" \
    "${system}:/etc/mpv/mpv.conf" \
    "./${system}/mpv/" || { echo "${red}Error copying over mpv configuration files.${nc}"; exit 1; }

## Script-opts
mkdir -p "./${system}/mpv/script-opts/"
rsync -ahuq "${system}:/etc/mpv/script-opts/osc.conf" "./${system}/mpv/script-opts/" || { echo "${red}Error copying over mpv/script-opts.${nc}"; exit 1; }

## Scripts
mkdir -p "./${system}/mpv/scripts/"
rsync -ahuq "${system}:/etc/mpv/scripts/osc_on_seek.lua" \
    "${system}:/etc/mpv/scripts/seek_to.lua" \
    "${system}:/etc/mpv/scripts/visualizer.lua" \
    "./${system}/mpv/scripts/" || { echo "${red}Error copying over mpv/scripts.${nc}"; exit 1; }

# OpenRC configuration files
mkdir -p "./${system}/conf.d/"
rsync -ahuq "${system}:/etc/conf.d/hostname" \
    "${system}:/etc/conf.d/keymaps" \
    "${system}:/etc/conf.d/net" \
    "${system}:/etc/conf.d/syncthing" \
    "./${system}/conf.d/" || { echo "${red}Error copying over OpenRC configuration files.${nc}"; exit 1; }

# PAM
mkdir -p "./${system}/pam.d/"
rsync -ahuq "${system}:/etc/pam.d/doas" \
    "${system}:/etc/pam.d/su" \
    "${system}:/etc/pam.d/system-local-login" \
    "./${system}/pam.d/" || { echo "${red}Error copying over PAM configuration files.${nc}"; exit 1; }

# Singular configuration files.
rsync -ahuq "${system}:/etc/environment" \
    "${system}:/etc/environment" \
    "${system}:/etc/i3blocks.conf" \
    "${system}:/etc/imv_config" \
    "${system}:/etc/resolv.conf.head" \
    "${system}:/etc/sysctl.conf" \
    "${system}:/etc/wgetrc" \
    "${system}:/etc/zathurarc" \
    "./${system}" || { echo "${red}Error copying over singular configuration files.${nc}"; exit 1; }

# X11
mkdir -p "./${system}/X11/xinit/"
rsync -ahuq "${system}:/etc/X11/xinit/xinitrc" "./${system}/X11/xinit/" || { echo "${red}Error copying over xinit configuration file.${nc}"; exit 1; }

# Portage
mkdir -p "./${system}/portage/"
rsync -ahuq "${system}:/etc/portage/make.conf" "./${system}/portage/" || { echo "${red}Error copying over make.conf for portage.${nc}"; exit 1; }

mkdir -p "./${system}/portage/env/"
rsync -ahuq "${system}:/etc/portage/env/no_hardening.conf" \
    "${system}:/etc/portage/env/no_lto.conf" \
    "${system}:/etc/portage/env/no_tmpfs.conf" \
    "${system}:/etc/portage/env/no_trapv.conf" \
    "./${system}/portage/env/" || { echo "${red}Error copying env files for portage.${nc}"; exit 1; }

mkdir -p "./${system}/portage/package.env/"
rsync -ahuq "${system}:/etc/portage/package.env/package.env" "./${system}/portage/package.env/" || { echo "${red}Error copying over package.env files for portage.${nc}"; exit 1; }

mkdir -p "./${system}/portage/package.license/"
rsync -ahuq "${system}:/etc/portage/package.license/package.license" "./${system}/portage/package.license/" || { echo "${red}Error copying over package.license for portage.${nc}"; exit 1; }

mkdir -p "./${system}/portage/package.mask/"
rsync -ahuq "${system}:/etc/portage/package.mask/deny.mask" "./${system}/portage/package.mask/" || { echo "${red}Error copying over package.mask files for portage.${nc}"; exit 1; }

mkdir -p "./${system}/portage/package.unmask/"
rsync -ahuq "${system}:/etc/portage/package.unmask/allow.unmask" "./${system}/portage/package.unmask/" || { echo "${red}Error copying over package.unmask files for portage.${nc}"; exit 1; }

mkdir -p "./${system}/portage/package.use/"
rsync -ahuq "${system}:/etc/portage/package.use/disable.use" \
    "${system}:/etc/portage/package.use/enable.use" \
    "${system}:/etc/portage/package.use/x.use" \
    "./${system}/portage/package.use/" || { echo "${red}Error copying over package.use files for portage.${nc}"; exit 1; }

mkdir -p "./${system}/portage/repos.conf/"
rsync -ahuq "${system}:/etc/portage/repos.conf/repos.conf" "./${system}/portage/repos.conf/" || { echo "${red}Error copying over repos.conf for portage.${nc}"; exit 1; }

mkdir -p "./${system}/portage/savedconfig/sys-kernel/"
rsync -ahuq "${system}:/etc/portage/savedconfig/sys-kernel/linux-firmware" "./${system}/portage/savedconfig/sys-kernel/" || { echo "${red}Error copying over linux-firmware config for portage.${nc}"; exit 1; }

mkdir -p "./${system}/portage/sets/"
rsync -ahuq "${system}:/etc/portage/sets/llvm-tc" "./${system}/portage/sets/" || { echo "${red}Error copying over portage sets.${nc}"; exit 1; }

# SSH
mkdir -p "./${system}/ssh/"
touch "./${system}/ssh/sshd_config"
echo "You have to copy over the sshd_config file for ${system} manually."

# Stubby
mkdir -p "./${system}/stubby/"
rsync -ahuq "${system}:/etc/stubby/stubby.yml" "./${system}/stubby/" || { echo "${red}Error copying over stubby configuration file.${nc}"; exit 1; }

# Wireplumber
mkdir -p "./${system}/wireplumber/wireplumber.conf.d/"
rsync -ahuq "${system}:/etc/wireplumber/wireplumber.conf.d/90-rename_main_output.conf" "./${system}/wireplumber/wireplumber.conf.d/" || { echo "${red}Error copying over wireplumber configuration files.${nc}"; exit 1; }

# XDG configuration files

## Basic
mkdir -p "./${system}/xdg/"
rsync -ahuq "${system}:/etc/xdg/mimeapps.list" \
    "${system}:/etc/xdg/user-dirs.conf" \
    "${system}:/etc/xdg/user-dirs.defaults" \
    "./${system}/xdg/" || { echo "${red}Error copying over XDG configuration files.${nc}"; exit 1; } 

## Alacritty
mkdir -p "./${system}/xdg/alacritty/"
rsync -ahuq "${system}:/etc/xdg/alacritty/alacritty.toml" \
    "${system}:/etc/xdg/alacritty/dark.toml" \
    "./${system}/xdg/alacritty/" || { echo "${red}Error copyin gover alacritty configuration files for XDG.${nc}"; exit 1; }

## Neovim

### Basic
mkdir -p "./${system}/xdg/nvim/"
rsync -ahuq "${system}:/etc/xdg/nvim/init.lua" \
    "${system}:/etc/xdg/nvim/sysinit.vim" \
    "./${system}/xdg/nvim/" || { echo "${red}Error copying over neovim configuration files for XDG.${nc}"; exit 1; }

### Colors
mkdir -p "./${system}/xdg/nvim/colors/"
rsync -ahuq "${system}:/etc/xdg/nvim/colors/aurora.vim" "./${system}/xdg/nvim/colors/" || { echo "${red}Error copying over neovim color configuration files for XDG.${nc}"; exit 1; }

### Ftplugins
mkdir -p "./${system}/xdg/nvim/ftplugin/"
rsync -ahuq "${system}:/etc/xdg/nvim/ftplugin/html.lua" \
    "${system}:/etc/xdg/nvim/ftplugin/tex.lua" \
    "${system}:/etc/xdg/nvim/ftplugin/text.lua" \
    "./${system}/xdg/nvim/ftplugin/" || { echo "${red}Error copying over neovim ftplugin files for XDG.${nc}"; exit 1; }

### Plugins
mkdir -p "./${system}/xdg/nvim/plugin/"
rsync -ahuq "${system}:/etc/xdg/nvim/plugin/vviki.vim" "./${system}/xdg/nvim/plugin/" || { echo "${red}Error copying over neovim plugin files for XDG.${nc}"; exit 1; }

# ZSH
mkdir -p "./${system}/zsh/"
rsync -ahuq "${system}:/etc/zsh/zprofile" \
    "${system}:/etc/zsh/zsh_aliases" \
    "${system}:/etc/zsh/zshenv" \
    "${system}:/etc/zsh/zshrc" \
    "./${system}/zsh/" || { echo "${red}Error copying over ZSH configuration files.${nc}"; exit 1; }

# System specifc configuration files.
if [ ${system} = "kotori" ]; then
    # Dracut
    rsync -ahuq "/etc/dracut.conf" "./${system}/"

    # Libvirt
    mkdir -p "./${system}/libvirt/"
    rsync -ahuq "${system}:/etc/libvirt/libvirtd.conf" "./${system}/libvirt/" || { echo "${red}Error copying over libvirtd.conf for libvirt.${nc}"; exit 1; }

    # Portage
    mkdir -p "./${system}/portage/env/"
    rsync -ahuq "${system}:/etc/portage/env/no_trapv.conf" "./${system}/portage/env/" || { echo "${red}Error copying over no_trapv.conf env file for portage.${nc}"; exit 1; }

    # Sway
    mkdir -p "./${system}/sway/"
    rsync -ahuq "${system}:/etc/sway/config" "./${system}/sway/" || { echo "${red}Error copying over Sway's configuration file.${nc}"; exit 1; }
elif [ ${system} = "delta" ]; then
    # Explicitly loaded modules
    mkdir -p "./${system}/modules-load.d/"
    rsync -ahuq "${system}:/etc/modules-load.d/nvidia.conf" "./${system}/modules-load.d/" || { echo "${red}Error copying over nvidia.conf for modules-load.d.${nc}"; exit 1; }

    # OpenRC configuration files
    mkdir -p "./${system}/conf.d/"
    rsync -ahuq "${system}:/etc/conf.d/syncthing" || { echo "${red}Error copying over syncthing OpenRC configuration file.${nc}"; exit 1; }

    # Portage
    mkdir -p "./${system}/portage/package.use/"
    rsync -ahuq "${system}:/etc/portage/package.use/abi_x86_32.use" "./${system}/portage/package.use/" || { echo "${red}Error copying over package.use/abi_x86_32.use for portage.${nc}"; exit 1; }

    # X11
    mkdir -p "./${system}/X11/xorg.conf.d/"
    rsync -ahuq "${system}:/etc/X11/xorg.conf.d/10-inputs.conf" \
        "${system}:/etc/X11/xorg.conf.d/10-monitor.conf" \
        "${system}:/etc/X11/xorg.conf.d/20-nvidia.conf" \
        "./${system}/X11/xorg.conf.d/"  || { echo "${red}Error copying over xorg.conf.d configuration files.${nc}"; exit 1; }
fi
