#!/bin/bash

# TermuxVoid-Theme Installer
# Version: 2.3
# Github: https://github.com/termuxvoid/TermuxVoid-Theme

# Color definitions
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
NC='\e[0m'

header() {
  clear
  echo -e "${CYAN}TermuxVoid-Theme Installer v2.3${NC}"
  echo -e "${GREEN}Custom terminal theming for Termux${NC}\n"
}

download_theme() {
  echo -e "${YELLOW}[*] Downloading theme...${NC}"
  if [ -d "TermuxVoid-Theme" ]; then
    rm -rf TermuxVoid-Theme
  fi
  git clone --quiet https://github.com/termuxvoid/TermuxVoid-Theme.git || {
    echo -e "${RED}[!] Download failed${NC}"
    exit 1
  }
}

customize() {
  # Name customization
  read -p "$(echo -e "${CYAN}Your name for prompt (blank for default): ${NC}")" username
  [ -n "$username" ] && sed -i "s/TermuxVoid/$username/g" TermuxVoid-Theme/assets/starship.toml

  # Banner setup
  echo -e "${YELLOW}[*] Setting up banner...${NC}"
  mkdir -p ~/.termux
  cp TermuxVoid-Theme/assets/tvr.png ~/.termux/ 2>/dev/null || echo -e "${RED}[!] Banner image not found${NC}"
  
  # Remove motd if exists
  [ -f "$PREFIX/etc/motd" ] && rm -f "$PREFIX/etc/motd"
}

install() {
  echo -e "${YELLOW}[*] Installing files...${NC}"
  mkdir -p ~/.config/{fish,starship.toml} 2>/dev/null
  cp TermuxVoid-Theme/assets/config.fish ~/.config/fish/
  cp TermuxVoid-Theme/assets/starship.toml ~/.config/
  cp TermuxVoid-Theme/assets/colors.properties ~/.termux/
  cp TermuxVoid-Theme/assets/font.ttf ~/.termux/
}

complete_install() {
  rm -rf TermuxVoid-Theme
  echo -e "\n${GREEN}[✓] Installation complete!${NC}"
  echo -e "${YELLOW}Restart Termux to apply changes${NC}"
}

# Main execution
header
read -p "$(echo -e "${CYAN}Proceed with installation? [Y/n]: ${NC}")" confirm
case "$confirm" in
  [nN]) exit ;;
  *) 
    download_theme
    customize
    install
    complete_install
    ;;
esac
