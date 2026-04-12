#!/bin/bash

# Colors
blue='\033[0;36m'
green='\033[0;32m'
yellow='\033[1;33m'
red='\033[0;31m'
nocolor='\033[0m'

sudo -v
while true; do sudo -v; sleep 60; done &
sudo_pid=$!
trap "kill $sudo_pid" EXIT

echo -e "${blue}##########################################${nocolor}"
echo -e "${blue}##   Remote Mouse installation script   ##${nocolor}"
echo -e "${blue}##########################################${nocolor}"
echo ""
echo -e "${red}You MUST run this script from the same folder where all the Remote Mouse files are.${nocolor}"
echo ""
echo -e "${yellow}This script will:${nocolor}"
echo -e "${yellow}01.${nocolor} Check if you're using one of the supported distros: Ubuntu, Arch and Fedora;"
echo -e "${yellow}02.${nocolor} Copy the \"Remote Mouse\" files to \"~/.local/bin/Remote_Mouse/\";"
echo -e "${yellow}03.${nocolor} Create the .desktop file in \"/.local/share/applications\";"
echo -e "${yellow}04.${nocolor} Update the desktop database so the shortcut can show up at the apps menu."
echo ""
echo -e "${yellow}Press ENTER to start the installation or CTRL+C to cancel.${nocolor}"
read -r

#----------------------------------------------
# ---STAGE 1: CHECKING FOR COMPATIBLE DISTRO---
#----------------------------------------------

# Check if running on Ubuntu:
if command -v apt-get &> /dev/null; then
  echo -e "${blue}\nUpdating package manager on Ubuntu...\n${nocolor}"
  sudo apt-get update
  echo -e "${blue}Installing must-have pre-requisites on Ubuntu...\n${nocolor}"
  sudo apt-get install xclip -y
  sudo apt install --reinstall libxcb-xinerama0 -y

# Check if running on Arch:
elif command -v pacman &> /dev/null; then
  echo -e "${blue}\nUpdating package manager and installing must-have pre-requisites on Arch Linux...\n${nocolor}"
  sudo pacman -S --noconfirm xclip

# Check if running on Fedora:
elif command -v dnf &> /dev/null; then
  echo -e "${blue}\nInstalling must-have pre-requisites on Fedora...\n${nocolor}"
  sudo dnf install -y xclip libxcb

# Error message:
else
  echo -e "${red}\nError: this script is only compatible with Ubuntu, Arch and Fedora.\n${nocolor}"
  exit 1
fi

#---------------------------------------------------------------------------------
# ---STAGE 2: COPY FILES TO INSTALLATION FOLDER AND GIVING EXECUTION PERMISSION---
#---------------------------------------------------------------------------------

echo -e "${blue}\nCreating installation folder in \"~/.local/bin/Remote_Mouse\"...\n${nocolor}"
mkdir -p "$HOME/.local/bin/Remote_Mouse/"

echo -e "${blue}\nCopying files to the installation folder...\n${nocolor}"
source=$(cd -- "$(dirname -- "$0")" && pwd)
destination="$HOME/.local/bin/Remote_Mouse/"

if [ -f "$source/RemoteMouse" ]; then
    cp -r "$source"/* "$destination"
    chmod +x "$destination/RemoteMouse"
else
    echo -e "${red}Error: RemoteMouse executable not found! Check your downloaded files.${nocolor}"
    exit 1
fi

#--------------------------------------
# ---STAGE 3: CREATING .DESKTOP FILE---
#--------------------------------------

echo -e "${blue}\nCreating desktop file...\n${nocolor}"

mkdir -p "$HOME/.local/share/applications"

echo -e "[Desktop Entry]\n"\
"Name=Remote Mouse\n"\
"GenericName=Remote Mouse\n"\
"Exec=$HOME/.local/bin/Remote_Mouse/RemoteMouse\n"\
"Path=$HOME/.local/bin/Remote_Mouse\n"\
"Icon=$HOME/.local/bin/Remote_Mouse/images/icon_linux_taskbar_green@3x.png\n"\
"Type=Application\n"\
"Categories=Utility;\n"\
"Keywords=Remote;Mouse;Keyboard;Control;\n"\
"StartupNotify=false\n" | tee "$HOME/.local/share/applications/remotemouse.desktop" > /dev/null

if command -v update-desktop-database &> /dev/null; then
  update-desktop-database "$HOME/.local/share/applications"
fi

echo -e "${green}\nThe script execution is finished. You can run the app by looking for Remote Mouse in your apps menu.${nocolor}"
