#!/bin/bash

# -----------------------------------------------------
#  Blueprint Auto Installer
#  Clean UI • Animations • Stable Spinner • ASCII Art
# -----------------------------------------------------

# Colors
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
YELLOW="\e[33m"
MAGENTA="\e[35m"
RESET="\e[0m"

# ASCII Art Banner
banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"

           _____  _____   ____  _   _     _____ _   _  _____ _______       _      _       ______ _____  
     /\   |  __ \|  __ \ / __ \| \ | |   |_   _| \ | |/ ____|__   __|/\   | |    | |    |  ____|  __ \ 
    /  \  | |  | | |  | | |  | |  \| |     | | |  \| | (___    | |  /  \  | |    | |    | |__  | |__) |
   / /\ \ | |  | | |  | | |  | | . ` |     | | | . ` |\___ \   | | / /\ \ | |    | |    |  __| |  _  / 
  / ____ \| |__| | |__| | |__| | |\  |    _| |_| |\  |____) |  | |/ ____ \| |____| |____| |____| | \ \ 
 /_/    \_\_____/|_____/ \____/|_| \_|   |_____|_| \_|_____/   |_/_/    \_\______|______|______|_|  \_\
                                                                                                       
                                                                                                                                                                          
EOF
    echo -e "${RESET}"
}

# Spinner Animation
spinner() {
    local pid=$1
    local delay=0.1
    local spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

    while kill -0 "$pid" 2>/dev/null; do
        for frame in "${spin[@]}"; do
            printf "\r${MAGENTA}Installing... ${frame}${RESET}"
            sleep $delay
        done
    done

    printf "\r${GREEN}✓ Done!${RESET}        \n"
}

# Run Banner
banner

echo -e "${YELLOW}🔍 Searching for .blueprint files...${RESET}"
sleep 1

# Detect blueprint files
mapfile -t FILES < <(ls *.blueprint 2>/dev/null)

if (( ${#FILES[@]} == 0 )); then
    echo -e "${RED}❌ No .blueprint files found!${RESET}"
    exit 1
fi

echo -e "${GREEN}✓ Found ${#FILES[@]} blueprint file(s):${RESET}"
echo ""

i=1
for file in "${FILES[@]}"; do
    echo -e "  ${CYAN}$i.${RESET} $file"
    ((i++))
done
echo ""

read -rp "$(echo -e ${YELLOW}'Do you want to install all blueprints? (y/n): '${RESET})" confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${RED}Cancelled.${RESET}"
    exit 0
fi

echo ""
echo -e "${BLUE}⚡ Starting installation...${RESET}"
echo ""

# Install loop
for f in "${FILES[@]}"; do
    echo -e "${CYAN}➡ Installing: ${MAGENTA}$f${RESET}"

    ( blueprint -install "$f" ) &
    installer_pid=$!

    spinner $installer_pid

    echo ""
done

echo -e "${GREEN}🎉 All blueprints installed successfully!${RESET}"
echo ""
echo -e "${BLUE}✨ Thank you for using Blueprint Installer!${RESET}"
echo ""
