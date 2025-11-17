#!/bin/bash
#=========================================================
#   ⭐ BLUEPRINT AUTO INSTALLER (Improved Edition)
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
EOF
echo -e "${RESET}"

echo -e "${GREEN}AUTO BLUEPRINT INSTALLER — Improved Version${RESET}"
echo

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
    exit 1
}

#============ CHECK COMMAND ============#
require() {
    command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

#============ REQUIRED COMMANDS ============#
for cmd in curl wget unzip git tee sudo; do
    require "$cmd"
done

#============ APT UPDATE ============#
loading "Updating system"
sudo apt update -y || fail "System update failed"
sudo apt upgrade -y || fail "System upgrade failed"

#============ INSTALL REQUIRED PACKAGES ============#
loading "Installing dependencies"
sudo apt install -y curl wget unzip git zip ca-certificates gnupg || fail "Failed to install required packages"

#============ VERIFY PTERODACTYL DIR ============#
if [[ ! -d "/var/www/pterodactyl" ]]; then
    fail "/var/www/pterodactyl directory not found. Install Pterodactyl first!"
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

#============ INSTALL NODE 20 + YARN (Official Way) ============#
loading "Setting up NodeSource repo"

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
    | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null

loading "Installing Node.js 20"
sudo apt update -y || fail "Node repo update failed"
sudo apt install -y nodejs || fail "Node.js installation failed"

loading "Enabling Corepack & Yarn"
sudo corepack enable || true
sudo npm install -g yarn || fail "Failed to install Yarn"

loading "Installing frontend dependencies"
yarn install || fail "Yarn failed to install dependencies"

#============ BLUEPRINT CONFIG ============#
loading "Creating .blueprintrc"

cat <<EOF | sudo tee /var/www/pterodactyl/.blueprintrc >/dev/null
WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";
EOF

#============ RUN BLUEPRINT INSTALLER ============#
[[ ! -f "/var/www/pterodactyl/blueprint.sh" ]] && fail "blueprint.sh missing! Extraction failed!"

loading "Fixing permissions"
sudo chmod +x /var/www/pterodactyl/blueprint.sh

loading "Running Blueprint installer"
sudo bash /var/www/pterodactyl/blueprint.sh || fail "Blueprint failed to run"

#============ COMPLETE ============#
echo
echo -e "${GREEN}✔ Blueprint installation completed successfully!${RESET}"
echo -e "${CYAN}🎉 Your Pterodactyl Blueprint theme is now installed perfectly.${RESET}"
echo -e "${YELLOW}Reload panel: ${RESET}sudo php artisan cache:clear"
echo
