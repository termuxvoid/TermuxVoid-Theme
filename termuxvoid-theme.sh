#!/bin/bash

# TermuxVoid-Theme Installer
# Version: 3.2
# Github: https://github.com/termuxvoid/TermuxVoid-Theme
#
# This script installs and configures TermuxVoid-Theme with:
# - Fish shell setup
# - Starship prompt
# - Custom banner support
# - Automatic dependency installation

# Color definitions for better output formatting
RED='\e[1;31m'      # Error messages
GREEN='\e[1;32m'    # Success messages
YELLOW='\e[1;33m'   # Warnings and information
CYAN='\e[1;36m'     # User prompts
NC='\e[0m'          # No Color (reset)

# List of required packages for the theme to work properly
REQUIRED_PKGS=("fish" "starship" "git" "jp2a")  # Added starship as requested

# Display the script header with version information
show_header() {
  clear
  echo -e "${CYAN}TermuxVoid-Theme Installer v3.2${NC}"
  echo -e "${GREEN}Professional terminal customization for Termux${NC}\n"
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
    apt update -y && apt upgrade -y
    apt install -y "${missing_pkgs[@]}" || {
      echo -e "${RED}[!] Failed to install dependencies${NC}"
      exit 1
    }
    echo -e "${GREEN}[+] Dependencies installed successfully${NC}"
  else
    echo -e "${GREEN}[+] All dependencies are installed${NC}"
  fi
}

# Change default shell to Fish (required for theme)
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

# Download the theme repository from GitHub
fetch_theme() {
  echo -e "${YELLOW}[*] Downloading theme repository...${NC}"
  [ -d "TermuxVoid-Theme" ] && rm -rf TermuxVoid-Theme
  git clone --depth=1 --quiet https://github.com/termuxvoid/TermuxVoid-Theme.git || {
    echo -e "${RED}[!] Failed to clone repository${NC}"
    exit 1
  }
}

# Customize the prompt with user's name
customize_prompt() {
  read -p "$(echo -e "${CYAN}Enter your name for prompt (blank for default): ${NC}")" username
  [ -n "$username" ] && sed -i "s/TermuxVoid/$username/g" TermuxVoid-Theme/assets/starship.toml
}

# Configure terminal banner (optional)
setup_banner() {
  read -p "$(echo -e "${CYAN}Configure custom banner? [y/N]: ${NC}")" banner_choice
  if [[ "$banner_choice" =~ ^[Yy]$ ]]; then
    read -p "$(echo -e "${YELLOW}Enter custom banner path or blank for default: ${NC}")" banner_path
    
    # Create Termux config directory if it doesn't exist
    mkdir -p ~/.termux
    
    # Handle banner image selection
    if [ -z "$banner_path" ]; then
      # Use default banner if no path provided
      if [ -f "TermuxVoid-Theme/assets/tvr.png" ]; then
        cp TermuxVoid-Theme/assets/tvr.png ~/.termux/
        banner_path="$HOME/.termux/tvr.png"
        echo -e "${GREEN}[+] Using default banner${NC}"
      fi
    elif [ -f "$banner_path" ]; then
      # Use custom banner if valid path provided
      cp "$banner_path" ~/.termux/tvr.png
      banner_path="$HOME/.termux/tvr.png"
      echo -e "${GREEN}[+] Using custom banner${NC}"
    else
      echo -e "${RED}[!] File not found: $banner_path${NC}"
      return
    fi

    # Configure Fish to display the banner
    if [ -f "$banner_path" ]; then
      sed -i "s|#logo|jp2a -f --colors '$banner_path'|g" TermuxVoid-Theme/assets/config.fish
      [ -f "$PREFIX/etc/motd" ] && rm -f "$PREFIX/etc/motd"  # Remove default message
      echo -e "${GREEN}[+] Banner configured with jp2a command${NC}"
    fi
  fi
}

# Install all configuration files
install_files() {
  echo -e "${YELLOW}[*] Installing configuration files...${NC}"
  
  # Create necessary directories
  mkdir -p ~/.config/fish ~/.termux ~/.config
  
  # Fish shell configuration
  cp TermuxVoid-Theme/assets/config.fish ~/.config/fish/
  
  # Starship prompt configuration (now properly in ~/.config)
  cp TermuxVoid-Theme/assets/starship.toml ~/.config/
  
  # Termux appearance settings
  cp TermuxVoid-Theme/assets/{colors.properties,font.ttf} ~/.termux/
  
  echo -e "${GREEN}[+] All configuration files installed${NC}"
}

# Final installation completion message
complete_installation() {
  # Clean up downloaded files
  rm -rf TermuxVoid-Theme
  
  # Display completion message
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
  echo -e "- Banner requires jp2a package (already checked)"
  echo -e "- Starship prompt is now configured"
  
  # Wait for user acknowledgement
  read -p "$(echo -e "\n${CYAN}Press Enter to exit (then restart Termux)...${NC}")"
}

# Main execution flow
show_header                # Show welcome message
check_dependencies        # Verify and install required packages
set_fish_shell            # Change default shell to Fish
fetch_theme               # Download the theme repository
customize_prompt          # Optional prompt customization
setup_banner              # Optional banner configuration
install_files             # Install all configuration files
complete_installation     # Show completion message