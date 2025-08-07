#!/usr/bin/env bash

# TermuxVoid-Theme Installer
# Version: 3.3
# Author: TermuxVoid Team
# Github: https://github.com/termuxvoid/TermuxVoid-Theme
# Description: 
#   This script installs and configures TermuxVoid-Theme with:
#   - Fish shell setup
#   - Starship prompt configuration
#   - Optional custom banner support with jp2a
#   - Automatic dependency installation
#   - Custom MOTD modification
#   - Self-cleaning capability

# =============================================
# COLOR DEFINITIONS FOR OUTPUT FORMATTING
# =============================================
RED='\e[1;31m'      # Error messages
GREEN='\e[1;32m'    # Success messages
YELLOW='\e[1;33m'   # Warnings and information
CYAN='\e[1;36m'     # User prompts
NC='\e[0m'          # No Color (reset)

# =============================================
# PATH VARIABLES AND CONFIGURATION
# =============================================
THEME_DIR="$TMPDIR/TermuxVoid-Theme"  # Temporary directory for theme files
CONFIG_DIR="$HOME/.config"            # User configuration directory
TERMUX_DIR="$HOME/.termux"            # Termux specific configuration directory
BANNER_CONFIGURED=false               # Flag to track banner configuration
SCRIPT_NAME=$(basename "$0")          # Name of this installation script

# =============================================
# REQUIRED PACKAGES FOR THE THEME
# =============================================
REQUIRED_PKGS=(
    "fish"       # Fish shell - the default shell for this theme
    "starship"   # Starship prompt - customizable cross-shell prompt
    "git"        # Git - for cloning the repository
    "jp2a"       # JPEG to ASCII converter - for banner display
    "eza"        # Modern ls replacement - better file listing
)

# =============================================
# FUNCTION: show_header
# Displays the installation header with version info
# =============================================
show_header() {
    clear
    echo -e "${CYAN}TermuxVoid-Theme Installer v3.3${NC}"
    echo -e "${GREEN}Professional terminal customization for Termux${NC}\n"
    echo -e "${YELLOW}This script will:${NC}"
    echo -e " • Install Fish shell and set as default"
    echo -e " • Configure Starship prompt"
    echo -e " • Set up Termux color scheme"
    echo -e " • Optionally configure custom banner"
    echo -e " • Modify MOTD display"
    echo -e " • Clean up after installation\n"
}

# =============================================
# FUNCTION: cleanup
# Removes temporary files and self-destructs
# =============================================
cleanup() {
    echo -e "${YELLOW}[*] Cleaning up installation files...${NC}"
    
    # Remove the temporary theme directory
    if [ -d "$THEME_DIR" ]; then
        rm -rf "$THEME_DIR"
        echo -e "${GREEN}[+] Removed theme repository${NC}"
    fi
    
    # Self-destruct the installer script
    if [ -f "$SCRIPT_NAME" ]; then
        rm -f "$SCRIPT_NAME"
        echo -e "${GREEN}[+] Removed installation script${NC}"
    elif [ -f "$(pwd)/$SCRIPT_NAME" ]; then
        rm -f "$(pwd)/$SCRIPT_NAME"
        echo -e "${GREEN}[+] Removed installation script${NC}"
    fi
}

# =============================================
# FUNCTION: check_dependencies
# Verifies and installs required packages
# =============================================
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
        if apt update -y && apt upgrade -y; then
            if apt install -y "${missing_pkgs[@]}"; then
                echo -e "${GREEN}[+] Dependencies installed successfully${NC}"
            else
                echo -e "${RED}[!] Failed to install dependencies${NC}"
                exit 1
            fi
        else
            echo -e "${RED}[!] Failed to update package lists${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[+] All dependencies are installed${NC}"
    fi
}

# =============================================
# FUNCTION: set_fish_shell
# Changes the default shell to Fish
# =============================================
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
    else
        echo -e "${GREEN}[✓] Fish is already the default shell${NC}"
    fi
}

# =============================================
# FUNCTION: fetch_theme
# Downloads the theme repository
# =============================================
fetch_theme() {
    echo -e "${YELLOW}[*] Downloading theme repository...${NC}"
    [ -d "$THEME_DIR" ] && rm -rf "$THEME_DIR"
    
    if git clone --depth=1 --quiet https://github.com/termuxvoid/TermuxVoid-Theme.git "$THEME_DIR"; then
        echo -e "${GREEN}[+] Theme repository cloned successfully${NC}"
    else
        echo -e "${RED}[!] Failed to clone repository${NC}"
        echo -e "${YELLOW}Please check your internet connection and try again.${NC}"
        exit 1
    fi
}

# =============================================
# FUNCTION: customize_prompt
# Personalizes the prompt with user's name
# =============================================
customize_prompt() {
    read -p "$(echo -e "${CYAN}Enter your name for prompt (blank for default 'TermuxVoid'): ${NC}")" username
    if [ -n "$username" ]; then
        if sed -i "s/TermuxVoid/$username/g" "$THEME_DIR/assets/starship.toml"; then
            echo -e "${GREEN}[+] Prompt customized with your name${NC}"
        else
            echo -e "${RED}[!] Failed to customize prompt${NC}"
        fi
    else
        echo -e "${YELLOW}[*] Using default prompt name${NC}"
    fi
}

# =============================================
# FUNCTION: setup_banner
# Configures custom banner (optional)
# =============================================
setup_banner() {
    read -p "$(echo -e "${CYAN}Configure custom banner? [y/N]: ${NC}")" banner_choice
    
    if [[ "$banner_choice" =~ ^[Yy]$ ]]; then
        BANNER_CONFIGURED=true
        read -p "$(echo -e "${YELLOW}Enter custom banner path or blank for default: ${NC}")" banner_path
        
        # Create Termux directory if it doesn't exist
        mkdir -p "$TERMUX_DIR"
        
        # Handle banner image selection
        if [ -z "$banner_path" ]; then
            # Use default banner if no path provided
            if [ -f "$THEME_DIR/assets/tvr.png" ]; then
                if cp "$THEME_DIR/assets/tvr.png" "$TERMUX_DIR/"; then
                    banner_path="$TERMUX_DIR/tvr.png"
                    echo -e "${GREEN}[+] Using default banner${NC}"
                else
                    echo -e "${RED}[!] Failed to copy default banner${NC}"
                    return
                fi
            fi
        elif [ -f "$banner_path" ]; then
            # Use custom banner if valid path provided
            if cp "$banner_path" "$TERMUX_DIR/tvr.png"; then
                banner_path="$TERMUX_DIR/tvr.png"
                echo -e "${GREEN}[+] Using custom banner${NC}"
            else
                echo -e "${RED}[!] Failed to copy custom banner${NC}"
                return
            fi
        else
            echo -e "${RED}[!] File not found: $banner_path${NC}"
            return
        fi

        # Configure banner display if image exists
        if [ -f "$banner_path" ]; then
            # Remove motd file if it exists
            [ -f "$PREFIX/etc/motd" ] && rm -f "$PREFIX/etc/motd"
            
            # Install welcome script
            if [ -f "$THEME_DIR/assets/wlcm.sh" ]; then
                if cp "$THEME_DIR/assets/wlcm.sh" "$TERMUX_DIR/" && chmod +x "$TERMUX_DIR/wlcm.sh"; then
                    echo -e "${GREEN}[+] Installed welcome script to $TERMUX_DIR/wlcm.sh${NC}"
                    
                    # Add the welcome script execution to fish config
                    if sed -i "s|#logo|bash ~/.termux/wlcm.sh\njp2a -f --colors '$banner_path'|g" "$THEME_DIR/assets/config.fish"; then
                        echo -e "${GREEN}[+] Configured Fish to display banner${NC}"
                    else
                        echo -e "${RED}[!] Failed to configure Fish banner display${NC}"
                    fi
                else
                    echo -e "${RED}[!] Failed to install welcome script${NC}"
                fi
            else
                echo -e "${RED}[!] wlcm.sh not found in theme assets${NC}"
            fi
        fi
    else
        # Modify motd when banner is not configured
        if [ -f "$PREFIX/etc/motd" ]; then
            # Change welcome message
            if sed -i 's/Welcome to Termux!/Welcome to TermuxVoid!/g' "$PREFIX/etc/motd"; then
                echo -e "${GREEN}[+] Modified welcome message in motd${NC}"
            else
                echo -e "${RED}[!] Failed to modify welcome message${NC}"
            fi
            
            # Change issue reporting URL
            if sed -i 's|Report issues at https://termux.dev/issues|Termux Void Repo https://termuxvoid.github.io|g' "$PREFIX/etc/motd"; then
                echo -e "${GREEN}[+] Modified issue reporting URL in motd${NC}"
            else
                echo -e "${RED}[!] Failed to modify issue reporting URL${NC}"
            fi
        else
            echo -e "${YELLOW}[!] motd file not found${NC}"
        fi
    fi
}

# =============================================
# FUNCTION: install_files
# Installs all configuration files
# =============================================
install_files() {
    echo -e "${YELLOW}[*] Installing configuration files...${NC}"
    
    # Create necessary directories
    mkdir -p "$CONFIG_DIR/fish" "$TERMUX_DIR" "$CONFIG_DIR"
    
    # Install Fish configuration
    if cp "$THEME_DIR/assets/config.fish" "$CONFIG_DIR/fish/"; then
        echo -e "${GREEN}[+] Fish configuration installed${NC}"
    else
        echo -e "${RED}[!] Failed to install Fish configuration${NC}"
    fi
    
    # Install Starship configuration
    if cp "$THEME_DIR/assets/starship.toml" "$CONFIG_DIR/"; then
        echo -e "${GREEN}[+] Starship configuration installed${NC}"
    else
        echo -e "${RED}[!] Failed to install Starship configuration${NC}"
    fi
    
    # Install Termux color scheme
    if cp "$THEME_DIR/assets/colors.properties" "$TERMUX_DIR/"; then
        echo -e "${GREEN}[+] Termux color scheme installed${NC}"
    else
        echo -e "${RED}[!] Failed to install color scheme${NC}"
    fi
    
    # Install Termux font
    if cp "$THEME_DIR/assets/font.ttf" "$TERMUX_DIR/"; then
        echo -e "${GREEN}[+] Termux font installed${NC}"
    else
        echo -e "${RED}[!] Failed to install font${NC}"
    fi
}

# =============================================
# FUNCTION: complete_installation
# Displays final instructions and cleans up
# =============================================
complete_installation() {
    echo -e "\n${GREEN}============================================${NC}"
    echo -e "${GREEN}[✓] Installation completed successfully!${NC}"
    echo -e "${GREEN}============================================${NC}"
    
    # Important restart instructions
    echo -e "\n${RED}IMPORTANT:${NC}"
    echo -e "1. Fully close the Termux app"
    echo -e "2. Reopen Termux to apply changes\n"
    
    # Additional notes for user
    echo -e "${YELLOW}Notes:${NC}"
    echo -e "- Default shell changed to Fish"
    echo -e "- Starship prompt configured"
    echo -e "- Color scheme and font installed"
    
    # Show banner-specific notes if configured
    if [ "$BANNER_CONFIGURED" = true ]; then
        echo -e "- Custom banner configured (requires jp2a)"
        echo -e "- Welcome script installed to ~/.termux/wlcm.sh"
    else
        echo -e "- MOTD message modified"
    fi
    
    # Clean up installation files
    cleanup
    
    # Wait for user acknowledgement
    read -p "$(echo -e "\n${CYAN}Press Enter to exit...${NC}")"
}

# =============================================
# MAIN EXECUTION FLOW
# =============================================
show_header
check_dependencies
set_fish_shell
fetch_theme
customize_prompt
setup_banner
install_files
complete_installation
