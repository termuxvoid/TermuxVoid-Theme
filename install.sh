#!/bin/bash

# TermuxVoid-Theme Installer
# Version: 2.6
# Github: https://github.com/termuxvoid/TermuxVoid-Theme

# Color definitions
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
NC='\e[0m'

show_header() {
  clear
  echo -e "${CYAN}TermuxVoid-Theme Installer v2.6${NC}"
  echo -e "${GREEN}Complete terminal customization for Termux${NC}\n"
}

fetch_theme() {
  echo -e "${YELLOW}[*] Downloading TermuxVoid-Theme...${NC}"
  [ -d "TermuxVoid-Theme" ] && rm -rf TermuxVoid-Theme
  git clone --depth=1 --quiet https://github.com/termuxvoid/TermuxVoid-Theme.git || {
    echo -e "${RED}[!] Download failed${NC}"
    exit 1
  }
}

customize_prompt() {
  read -p "$(echo -e "${CYAN}Enter your name for prompt (blank for default): ${NC}")" username
  [ -n "$username" ] && sed -i "s/TermuxVoid/$username/g" TermuxVoid-Theme/assets/starship.toml
}

setup_banner() {
  read -p "$(echo -e "${CYAN}Do you want a custom banner? [y/N]: ${NC}")" banner_choice
  if [[ "$banner_choice" =~ ^[Yy]$ ]]; then
    read -p "$(echo -e "${YELLOW}Enter custom banner path or leave blank for default: ${NC}")" banner_path
    
    mkdir -p ~/.termux
    
    # Copy wlcm.sh for custom banner
    if [ -f "TermuxVoid-Theme/assets/wlcm.sh" ]; then
      cp TermuxVoid-Theme/assets/wlcm.sh ~/.termux/
      chmod +x ~/.termux/wlcm.sh
      echo -e "${GREEN}[+] Banner welcome script installed${NC}"
    fi

    if [ -z "$banner_path" ]; then
      # Use default banner
      if [ -f "TermuxVoid-Theme/assets/tvr.png" ]; then
        cp TermuxVoid-Theme/assets/tvr.png ~/.termux/
        banner_path="$HOME/.termux/tvr.png"
        echo -e "${GREEN}[+] Using default banner${NC}"
      else
        echo -e "${RED}[!] Default banner not found${NC}"
        return
      fi
    elif [ -f "$banner_path" ]; then
      # Use custom banner
      cp "$banner_path" ~/.termux/tvr.png
      banner_path="$HOME/.termux/tvr.png"
      echo -e "${GREEN}[+] Custom banner installed${NC}"
    else
      echo -e "${RED}[!] File not found: $banner_path${NC}"
      return
    fi

    # Replace #logo in config.fish
    sed -i "s|#logo|~/.termux/wlcm.sh '$banner_path'|g" TermuxVoid-Theme/assets/config.fish
    [ -f "$PREFIX/etc/motd" ] && rm -f "$PREFIX/etc/motd"
    echo -e "${GREEN}[+] Banner configuration complete${NC}"
  fi
}

install_files() {
  echo -e "${YELLOW}[*] Installing theme files...${NC}"
  mkdir -p ~/.config/fish ~/.termux
  
  # Fish configuration
  cp TermuxVoid-Theme/assets/config.fish ~/.config/fish/
  
  # Other theme files
  cp TermuxVoid-Theme/assets/{starship.toml,colors.properties,font.ttf} ~/.termux/
  mv ~/.termux/{starship.toml} ~/.config/
  
  echo -e "${GREEN}[+] All files installed${NC}"
}

complete_install() {
  rm -rf TermuxVoid-Theme
  echo -e "\n${GREEN}[✓] Installation complete!${NC}"
  echo -e "${YELLOW}To complete setup:${NC}"
  echo -e "1. Restart Termux"
  echo -e "2. Or run: ${CYAN}source ~/.config/fish/config.fish${NC}"
  echo -e "\n${YELLOW}For banner display:${NC}"
  echo -e "- Install jp2a: ${CYAN}pkg install jp2a${NC}"
  echo -e "- Make sure ~/.termux/wlcm.sh is executable"
}

# Main execution
show_header
read -p "$(echo -e "${CYAN}Start installation? [Y/n]: ${NC}")" confirm
[[ "$confirm" =~ ^[Nn]$ ]] && exit

fetch_theme
customize_prompt
setup_banner
install_files
complete_install
