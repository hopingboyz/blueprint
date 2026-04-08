#!/bin/bash
#=========================================================
#   ⭐ BLUEPRINT AUTO INSTALLER (Optimized Edition)
#      Compatible with Debian/Ubuntu + Pterodactyl
#      Created by Hopingboyz — Fully Optimized
#=========================================================

set -o errexit
set -o pipefail
set -o nounset

#============ COLORS ============#
CYAN="\e[96m"
GREEN="\e[92m"
RED="\e[91m"
YELLOW="\e[93m"
RESET="\e[0m"

clear

#============ ASCII BANNER ============#
echo -e "${CYAN}"
cat << "EOF"
  ____  _     _    _ ______ _____  _____  _____ _   _ _______     _____ _   _  _____ _______       _      _      ______ _____  
 |  _ \| |   | |  | |  ____|  __ \|  __ \|_   _| \ | |__   __|   |_   _| \ | |/ ____|__   __|/\   | |    | |    |  ____|  __ \ 
 | |_) | |   | |  | | |__  | |__) | |__) | | | |  \| |  | |        | | |  \| | (___    | |  /  \  | |    | |    | |__  | |__) |
 |  _ <| |   | |  | |  __| |  ___/|  _  /  | | | . ` |  | |        | | | . ` |\___ \   | | / /\ \ | |    | |    |  __| |  _  / 
 | |_) | |___| |__| | |____| |    | | \ \ _| |_| |\  |  | |       _| |_| |\  |____) |  | |/ ____ \| |____| |____| |____| | \ \ 
 |____/|______\____/|______|_|    |_|  \_\_____|_| \_|  |_|      |_____|_| \_|_____/   |_/_/    \_\______|______|______|_|  \_\

 Made By Smith
EOF
echo -e "${RESET}"

echo -e "${GREEN}AUTO BLUEPRINT INSTALLER — Optimized Version${RESET}"
echo

#============ LOGGING ============#
LOG_FILE="/var/log/blueprint-installer.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

#============ LOADING ANIMATION ============#
loading() {
    local msg="$1"
    echo -ne "${YELLOW}${msg}${RESET}"
    for _ in {1..3}; do
        echo -ne "."
        sleep 0.3
    done
    echo
}

#============ ERROR EXIT ============#
fail() {
    echo -e "${RED}❌ ERROR: $1${RESET}"
    log "ERROR: $1"
    exit 1
}

#============ CHECK COMMAND ============#
require() {
    if ! command -v "$1" >/dev/null 2>&1; then
        fail "Missing required command: $1"
    fi
}

#============ CHECK IF ALREADY INSTALLED ============#
check_already_installed() {
    if [[ -f "/var/www/reviactyl/.blueprint-installed" ]]; then
        echo -e "${YELLOW}⚠️  Blueprint appears to be already installed.${RESET}"
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Installation cancelled.${RESET}"
            exit 0
        fi
    fi
}

#============ CHECK ROOT PRIVILEGES ============#
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  Warning: Running as root is not recommended.${RESET}"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    elif [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        fail "This script requires sudo privileges. Run with sudo or as root."
    fi
}

#============ INSTALL PACKAGE IF MISSING ============#
install_if_missing() {
    local pkg="$1"
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        loading "Installing $pkg"
        sudo apt install -y "$pkg" || fail "Failed to install $pkg"
        log "Installed package: $pkg"
    else
        log "Package already installed: $pkg"
    fi
}

#============ MAIN SCRIPT ============#
main() {
    log "Starting Blueprint installation"
    
    # Initial checks
    check_privileges
    check_already_installed

    #============ REQUIRED COMMANDS ============#
    loading "Checking system requirements"
    for cmd in curl wget unzip git; do
        require "$cmd"
    done

    #============ SYSTEM UPDATE ============#
    loading "Updating system packages"
    sudo apt update -y || fail "System update failed"
    sudo apt upgrade -y || fail "System upgrade failed"

    #============ INSTALL REQUIRED PACKAGES ============#
    loading "Checking and installing dependencies"
    for pkg in curl wget unzip git zip ca-certificates gnupg lsb-release; do
        install_if_missing "$pkg"
    done

    #============ VERIFY PTERODACTYL DIR ============#
    if [[ ! -d "/var/www/reviactyl" ]]; then
        fail "/var/www/reviactyl directory not found. Install Pterodactyl first!"
    fi

    cd /var/www/pterodactyl || fail "Unable to enter Pterodactyl directory"

    #============ DOWNLOAD LATEST BLUEPRINT ============#
    loading "Fetching latest Blueprint release"

    LATEST_URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
        | grep '"browser_download_url"' \
        | grep ".zip" \
        | head -n 1 \
        | cut -d '"' -f 4)

    [[ -z "$LATEST_URL" ]] && fail "Failed to get latest release URL"

    loading "Downloading Blueprint"
    wget -q "$LATEST_URL" -O blueprint.zip || fail "Download failed"

    loading "Extracting Blueprint"
    unzip -oq blueprint.zip || fail "Unzip failed"
    rm -f blueprint.zip

    #============ NODE.JS INSTALLATION ============#
    if ! command -v node >/dev/null 2>&1 || ! node --version | grep -q "v20"; then
        loading "Setting up Node.js 20"

        # Remove existing Node.js if wrong version
        if command -v node >/dev/null 2>&1; then
            loading "Removing existing Node.js version"
            sudo apt remove -y --purge nodejs npm || true
            sudo rm -rf /etc/apt/sources.list.d/nodesource.list
        fi

        # Install Node.js 20 using NodeSource
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || fail "NodeSource setup failed"
        sudo apt update -y
        sudo apt install -y nodejs || fail "Node.js installation failed"
        
        log "Node.js installed/updated to version 20"
    else
        loading "Node.js 20 already installed"
        log "Node.js 20 already present"
    fi

    #============ YARN SETUP ============#
    if ! command -v yarn >/dev/null 2>&1; then
        loading "Installing Yarn"
        sudo npm install -g corepack || fail "Corepack installation failed"
        sudo corepack enable || fail "Corepack enable failed"
        log "Yarn installed via corepack"
    else
        loading "Yarn already installed"
        log "Yarn already present"
    fi

    #============ FRONTEND DEPENDENCIES ============#
    loading "Installing frontend dependencies"
    yarn install --production=false || fail "Yarn failed to install dependencies"
    log "Frontend dependencies installed"

    #============ BLUEPRINT CONFIG ============#
    if [[ ! -f "/var/www/reviactyl/.blueprintrc" ]]; then
        loading "Creating .blueprintrc"
        cat <<EOF | sudo tee /var/www/reviactyl/.blueprintrc >/dev/null
WEBUSER="www-data"
OWNERSHIP="www-data:www-data"
USERSHELL="/bin/bash"
EOF
        log "Created .blueprintrc configuration"
    else
        loading ".blueprintrc already exists"
        log ".blueprintrc configuration already present"
    fi

    #============ RUN BLUEPRINT INSTALLER ============#
    if [[ ! -f "/var/www/reviactyl/blueprint.sh" ]]; then
        fail "blueprint.sh missing! Extraction failed!"
    fi

    loading "Fixing permissions"
    sudo chmod +x /var/www/reviactyl/blueprint.sh

    loading "Running Blueprint installer"
    sudo bash /var/www/reviactyl/blueprint.sh || fail "Blueprint failed to run"

    #============ MARK AS INSTALLED ============#
    sudo touch /var/www/reviactyl/.blueprint-installed
    log "Blueprint installation completed successfully"

    #============ COMPLETE ============#
    echo
    echo -e "${GREEN}✔ Blueprint installation completed successfully!${RESET}"
    echo -e "${CYAN}🎉 Your Pterodactyl Blueprint theme is now installed perfectly.${RESET}"
    echo
    echo -e "${YELLOW}Next steps:${RESET}"
    echo -e "${YELLOW}1. Clear cache:${RESET} sudo php artisan cache:clear"
    echo -e "${YELLOW}2. Restart queue:${RESET} sudo php artisan queue:restart"
    echo -e "${YELLOW}3. View logs:${RESET} tail -f $LOG_FILE"
    echo
    echo -e "${GREEN}Installation log: $LOG_FILE${RESET}"
}

# Run main function
main "$@"
