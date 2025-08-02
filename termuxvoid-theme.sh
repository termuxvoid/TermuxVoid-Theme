#!/usr/bin/env bash

# TermuxVoid-Theme Installer
# Version: 3.2
# Github: https://github.com/termuxvoid/TermuxVoid-Theme
#
# This script installs and configures TermuxVoid-Theme with:
# - Fish shell setup
# - Starship prompt
# - Optional custom banner support
# - Automatic dependency installation

# Color definitions for output formatting
RED='\e[1;31m'      # Error messages
GREEN='\e[1;32m'    # Success messages
YELLOW='\e[1;33m'   # Warnings and information
CYAN='\e[1;36m'     # User prompts
NC='\e[0m'          # No Color (reset)

# Path variables
THEME_DIR="$TMPDIR/TermuxVoid-Theme"
CONFIG_DIR="$HOME/.config"
TERMUX_DIR="$HOME/.termux"
BANNER_CONFIGURED=false

# Required packages for the theme
REQUIRED_PKGS=("fish" "starship" "git" "jp2a" "eza")

# Display the script header
show_header() {
  clear
  echo -e "${CYAN}TermuxVoid-Theme Installer v3.2${NC}"
  echo -e "${GREEN}Professional terminal customization for Termux${NC}\n"
}

# Clean up temporary files
cleanup() {
  echo -e "${YELLOW}[*] Cleaning up installation files...${NC}"
  if [ -d "$THEME_DIR" ]; then
    rm -rf "$THEME_DIR"
    echo -e "${GREEN}[+] Removed theme repository${NC}"
  fi
}

# Check and install missing dependencies
check_dependencies() {
  echo -e "${YELLOW}[*] Checking system dependencies...${NC}"
  missing_pkgs=()
  
  # Check each required package
  for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
      missing_pkgs+=("$pkg")
      echo -e "${RED}[!] $pkg not found${NC}"
    else
      echo -e "${GREEN}[✓] $pkg installed${NC}"
    fi
  done

  # Install missing packages if any
  if [ ${#missing_pkgs[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}[*] Installing missing packages...${NC}"
    pkg update -y && pkg upgrade -y
    pkg install -y "${missing_pkgs[@]}" || {
      echo -e "${RED}[!] Failed to install dependencies${NC}"
      exit 1
    }
    echo -e "${GREEN}[+] Dependencies installed successfully${NC}"
  else
    echo -e "${GREEN}[+] All dependencies are installed${NC}"
  fi
}

# Change default shell to Fish
set_fish_shell() {
  current_shell=$(basename "$SHELL")
  if [ "$current_shell" != "fish" ]; then
    echo -e "${YELLOW}[*] Changing shell to Fish...${NC}"
    if chsh -s fish &>/dev/null; then
      echo -e "${GREEN}[+] Default shell changed to Fish${NC}"
    else
      echo -e "${RED}[!] Failed to change shell${NC}"
      exit 1
    fi
  fi
}

# Download the theme repository
fetch_theme() {
  echo -e "${YELLOW}[*] Downloading theme repository to temp directory...${NC}"
  [ -d "$THEME_DIR" ] && rm -rf "$THEME_DIR"
  git clone --depth=1 --quiet https://github.com/termuxvoid/TermuxVoid-Theme.git "$THEME_DIR" || {
    echo -e "${RED}[!] Failed to clone repository${NC}"
    exit 1
  }
}

# Customize the prompt with user's name
customize_prompt() {
  read -p "$(echo -e "${CYAN}Enter your name for prompt (blank for default): ${NC}")" username
  [ -n "$username" ] && sed -i "s/TermuxVoid/$username/g" "$THEME_DIR/assets/starship.toml"
}

# Configure terminal banner (optional)
setup_banner() {
  read -p "$(echo -e "${CYAN}Configure custom banner? [y/N]: ${NC}")" banner_choice
  if [[ "$banner_choice" =~ ^[Yy]$ ]]; then
    BANNER_CONFIGURED=true
    read -p "$(echo -e "${YELLOW}Enter custom banner path or blank for default: ${NC}")" banner_path
    
    mkdir -p "$TERMUX_DIR"
    
    # Handle banner image selection
    if [ -z "$banner_path" ]; then
      # Use default banner if no path provided
      if [ -f "$THEME_DIR/assets/tvr.png" ]; then
        cp "$THEME_DIR/assets/tvr.png" "$TERMUX_DIR/"
        banner_path="$TERMUX_DIR/tvr.png"
        echo -e "${GREEN}[+] Using default banner${NC}"
      fi
    elif [ -f "$banner_path" ]; then
      # Use custom banner if valid path provided
      cp "$banner_path" "$TERMUX_DIR/tvr.png"
      banner_path="$TERMUX_DIR/tvr.png"
      echo -e "${GREEN}[+] Using custom banner${NC}"
    else
      echo -e "${RED}[!] File not found: $banner_path${NC}"
      return
    fi

    # Configure banner display if image exists
    if [ -f "$banner_path" ]; then
      # Configure fish to display the banner
      sed -i "s|#logo|jp2a -f --colors '$banner_path'|g" "$THEME_DIR/assets/config.fish"
      [ -f "$PREFIX/etc/motd" ] && rm -f "$PREFIX/etc/motd"
      
      # Install welcome script only when banner is configured
      if [ -f "$THEME_DIR/assets/wlcm.sh" ]; then
        cp "$THEME_DIR/assets/wlcm.sh" "$TERMUX_DIR/"
        chmod +x "$TERMUX_DIR/wlcm.sh"
        echo -e "${GREEN}[+] Installed welcome script to $TERMUX_DIR/wlcm.sh${NC}"
      else
        echo -e "${RED}[!] wlcm.sh not found in theme assets${NC}"
      fi
      
      echo -e "${GREEN}[+] Banner configured successfully${NC}"
    fi
  fi
}

# Install all configuration files
install_files() {
  echo -e "${YELLOW}[*] Installing configuration files...${NC}"
  
  # Create necessary directories
  mkdir -p "$CONFIG_DIR/fish" "$TERMUX_DIR" "$CONFIG_DIR"
  
  # Fish shell configuration
  cp "$THEME_DIR/assets/config.fish" "$CONFIG_DIR/fish/"
  
  # Starship prompt configuration
  cp "$THEME_DIR/assets/starship.toml" "$CONFIG_DIR/"
  
  # Termux appearance settings
  cp "$THEME_DIR/assets/"{colors.properties,font.ttf} "$TERMUX_DIR/"
  
  echo -e "${GREEN}[+] All configuration files installed${NC}"
}

# Final installation completion message
complete_installation() {
  cleanup
  echo -e "\n${GREEN}============================================${NC}"
  echo -e "${GREEN}[✓] Installation completed successfully!${NC}"
  echo -e "${GREEN}============================================${NC}"
  
  # Important restart instructions
  echo -e "\n${RED}IMPORTANT: RESTART TERMUX NOW TO APPLY CHANGES${NC}"
  echo -e "1. Fully close the Termux app"
  echo -e "2. Reopen Termux"
  
  # Additional notes for user
  echo -e "\n${YELLOW}Notes:${NC}"
  echo -e "- Your default shell has been changed to Fish"
  echo -e "- Starship prompt is now configured"
  
  # Show banner-specific notes if configured
  if [ "$BANNER_CONFIGURED" = true ]; then
    echo -e "- Custom banner configured (requires jp2a)"
    echo -e "- Welcome script installed to ~/.termux/wlcm.sh"
  fi
  
  # Wait for user acknowledgement
  read -p "$(echo -e "\n${CYAN}Press Enter to exit (then restart Termux)...${NC}")"
}

# Main execution flow
show_header
check_dependencies
set_fish_shell
fetch_theme
customize_prompt
setup_banner
install_files
complete_installation