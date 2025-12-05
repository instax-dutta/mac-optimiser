#!/bin/bash

# ==========================================
# 🚀 MAC ULTIMATE OPTIMIZER - ELITE EDITION
# ==========================================

# Colors & Styles
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Spinner Animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Cool Header
# Cool Header
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo -e "${CYAN}${BOLD}   MAC ULTIMATE OPTIMIZER   ${NC}"
    echo -e "${BLUE}   ======================   ${NC}"
    echo -e "${NC}"
    echo -e "${BLUE}      »» System Optimization & Maintenance Tool ««${NC}"
    echo -e "${BLUE}      »»       Safe Mode: ACTIVE [✔]            ««${NC}"
    echo ""
}

# System Status
# System Status
show_status() {
    # Get system info
    local uptime_info=$(uptime | awk -F'( |,|:)+' '{if ($6~/[0-9]+/) print $6"d "$8"h "$9"m"; else print $6"h "$7"m"}')
    local disk_info=$(df -h / | tail -1 | awk '{print $5}')
    local mem_info=$(ps -A -o %mem | awk '{s+=$1} END {print int(s)"%"}')
    
    echo -e "${BLUE}   ┌──────────────────────────────────────────────────┐${NC}"
    printf "${BLUE}   │${NC}  ${BOLD}%-46s${NC}  ${BLUE}│${NC}\n" "System Status"
    echo -e "${BLUE}   ├──────────────────────────────────────────────────┤${NC}"
    printf "${BLUE}   │${NC}  ${MAGENTA}%-14s${NC} : %-29s  ${BLUE}│${NC}\n" "• Uptime" "$uptime_info"
    printf "${BLUE}   │${NC}  ${MAGENTA}%-14s${NC} : %-29s  ${BLUE}│${NC}\n" "• Disk Usage" "$disk_info used"
    printf "${BLUE}   │${NC}  ${MAGENTA}%-14s${NC} : %-29s  ${BLUE}│${NC}\n" "• Memory" "$mem_info active"
    echo -e "${BLUE}   └──────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Helper for success/error
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✔] $1${NC}"
    else
        echo -e "${RED}[✘] $2${NC}"
    fi
}

# 1. System Cleanup
cleanup_system() {
    show_banner
    echo -e "${YELLOW}${BOLD}WARNING: This will clear system caches and logs.${NC}"
    echo -e "${YELLOW}It is HIGHLY RECOMMENDED to close all running applications (Chrome, Spotify, etc.) first.${NC}"
    echo ""
    read -p "Press [Enter] to continue or [Ctrl+C] to cancel..."
    
    echo ""
    echo -ne "${CYAN}→ Cleaning User Cache (~/Library/Caches)...${NC}"
    rm -rf ~/Library/Caches/* & spinner $!
    print_status "User Cache cleared" "Failed to clear User Cache"

    echo -ne "${CYAN}→ Cleaning System Logs...${NC}"
    sudo rm -rf /private/var/log/* 2>/dev/null & spinner $!
    print_status "System Logs cleared" "Failed to clear System Logs"

    echo -ne "${CYAN}→ Emptying Trash...${NC}"
    rm -rf ~/.Trash/* & spinner $!
    print_status "Trash emptied" "Failed to empty Trash"
    
    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        echo -ne "${CYAN}→ Cleaning Xcode DerivedData...${NC}"
        rm -rf ~/Library/Developer/Xcode/DerivedData/* & spinner $!
        print_status "Xcode DerivedData cleared" "Failed to clear DerivedData"
    fi

    echo -e "\n${GREEN}✨ System Cleanup Complete!${NC}"
    read -p "Press Enter to return..."
}

# 2. Memory Optimization
optimize_memory() {
    show_banner
    echo -ne "${CYAN}→ Purging inactive memory (RAM)...${NC}"
    sudo purge & spinner $!
    print_status "Memory purged" "Failed to purge memory"
    
    echo -e "\n${GREEN}✨ Memory Optimized!${NC}"
    read -p "Press Enter to return..."
}

# 3. Network Optimization
optimize_network() {
    show_banner
    echo -e "${BOLD}Network Booster${NC}"
    
    echo -ne "${CYAN}→ Disabling WiFi Power Save...${NC}"
    sudo defaults write /Library/Preferences/com.apple.wifi.plist WiFiPowerSave -int 0 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e " ${GREEN}[✔] Done${NC}"
    else
        echo -e " ${YELLOW}[!] Skipped (Not supported)${NC}"
    fi

    echo -ne "${CYAN}→ Flushing DNS cache...${NC}"
    (sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder) & spinner $!
    print_status "DNS cache flushed" "Failed to flush DNS"

    echo -ne "${CYAN}→ Resetting network interface (en0)...${NC}"
    (sudo ifconfig en0 down; sleep 1; sudo ifconfig en0 up) & spinner $!
    print_status "Interface en0 reset" "Failed to reset en0"

    echo -ne "${CYAN}→ Renewing DHCP lease...${NC}"
    sudo ipconfig set en0 DHCP 2>/dev/null & spinner $!
    print_status "DHCP lease renewed" "Failed to renew DHCP"
    
    echo -ne "${CYAN}→ Optimizing TCP/IP & DNS settings...${NC}"
    sudo sysctl -w net.inet.ip.ttl=65 > /dev/null 2>&1
    sudo sysctl -w net.inet.captive_portal=0 > /dev/null 2>&1
    sudo sysctl -w net.inet.tcp.sendspace=1048576 > /dev/null 2>&1
    sudo sysctl -w net.inet.tcp.recvspace=1048576 > /dev/null 2>&1
    echo -e " ${GREEN}[✔] Done${NC}"

    echo -e "\n${GREEN}🚀 Network Boosted!${NC}"
    read -p "Press Enter to return..."
}

# 4. Maintenance Scripts
run_maintenance() {
    show_banner
    echo -e "${CYAN}Running macOS Daily/Weekly/Monthly maintenance scripts...${NC}"
    echo -e "${YELLOW}(This might take a few moments)${NC}"
    
    echo -ne "→ Running Daily script..."
    sudo periodic daily & spinner $!
    echo -e " ${GREEN}[✔]${NC}"

    echo -ne "→ Running Weekly script..."
    sudo periodic weekly & spinner $!
    echo -e " ${GREEN}[✔]${NC}"

    echo -ne "→ Running Monthly script..."
    sudo periodic monthly & spinner $!
    echo -e " ${GREEN}[✔]${NC}"

    echo -e "\n${GREEN}✨ Maintenance Complete!${NC}"
    read -p "Press Enter to return..."
}

# 5. Reindex Spotlight
reindex_spotlight() {
    show_banner
    echo -e "${YELLOW}Warning: Reindexing Spotlight can take a while and use high CPU.${NC}"
    echo -e "${YELLOW}Only do this if your search is broken.${NC}"
    read -p "Are you sure? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo -ne "${CYAN}→ Starting Spotlight reindex...${NC}"
        sudo mdutil -E / > /dev/null 2>&1 & spinner $!
        print_status "Reindexing started in background" "Failed to start"
    else
        echo "Cancelled."
    fi
    read -p "Press Enter to return..."
}

# 6. Flush Print Queue
flush_print_queue() {
    show_banner
    echo -ne "${CYAN}→ Cancelling all print jobs...${NC}"
    cancel -a - & spinner $!
    print_status "Print queue flushed" "Failed to flush"
    read -p "Press Enter to return..."
}

# Main Menu Loop
while true; do
    show_banner
    show_status
    echo -e "${BOLD}Select an Optimization:${NC}"
    echo -e "  ${CYAN}1)${NC} 🧹 System Cleanup (Cache, Logs, Trash)"
    echo -e "  ${CYAN}2)${NC} 🧠 Optimize RAM (Purge Memory)"
    echo -e "  ${CYAN}3)${NC} ⚡ Boost Internet/Network"
    echo -e "  ${CYAN}4)${NC} 🛠  Run Maintenance Scripts"
    echo -e "  ${CYAN}5)${NC} 🖨  Flush Print Queue"
    echo -e "  ${CYAN}6)${NC} 🔍 Reindex Spotlight"
    echo -e "  ${CYAN}7)${NC} 🌟 Run ALL Safe Optimizations (1-4)"
    echo -e "  ${RED}8) 🚪 Exit${NC}"
    echo ""
    read -p "Choose option [1-8]: " option

    case $option in
        1) cleanup_system ;;
        2) optimize_memory ;;
        3) optimize_network ;;
        4) run_maintenance ;;
        5) flush_print_queue ;;
        6) reindex_spotlight ;;
        7) 
            cleanup_system
            optimize_memory
            optimize_network
            run_maintenance
            ;;
        8) 
            echo -e "\n${GREEN}Stay fast! Exiting...${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Invalid option.${NC}"
            sleep 1 
            ;;
    esac
done
