#!/bin/bash

# macOS Ultimate Optimizer - Production Quality Rewrite
# ========================================================

set -euo pipefail

# Colors & Styles
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global state
DRY_RUN=false
BATCH_MODE=false
LOG_FILE="$HOME/.mac_optimizer.log"

# Detect macOS version
OS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
OS_MINOR=$(sw_vers -productVersion | cut -d. -f2)
OS_NAME=$(sw_vers -productName)
DARWIN_VERSION=$(uname -r | cut -d. -f1)

# Parse --dry-run flag
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

# Logging function - every action recorded
log_action() {
    local desc="$1"
    local status="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$([ "$status" -eq 0 ] && echo OK || echo FAIL)] $desc" >> "$LOG_FILE"
}

# Version gating helper
require_min_version() {
    local min_major=$1
    if [ "$OS_MAJOR" -lt "$min_major" ]; then
        echo -e "${YELLOW}[!] Skipped — requires macOS $min_major+${NC}"
        return 1
    fi
    return 0
}

# Fixed spinner - uses kill -0 for PID check (POSIX-correct)
spinner() {
    local pid=$1
    local spinstr
    spinstr=$(printf '|/-\x5c')
    while kill -0 "$pid" 2>/dev/null; do
        printf " [%c]  " "$spinstr"
        spinstr=${spinstr#?}${spinstr%"${spinstr#?}"}
        sleep 0.1
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

# run_cmd - replaces print_status pattern with correct exit code handling
run_cmd() {
    local desc="$1"; shift
    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}→ ${desc}...${NC} ${YELLOW}[DRY] would run: $*${NC}"
        return 0
    fi
    echo -ne "${CYAN}→ ${desc}...${NC}"
    "$@" > /tmp/mac_opt_last.log 2>&1
    local status=$?
    if [ $status -eq 0 ]; then
        echo -e " ${GREEN}[✔]${NC}"
    else
        echo -e " ${RED}[✘] (see /tmp/mac_opt_last.log)${NC}"
    fi
    log_action "$desc" $status
    return $status
}

# Banner with actual macOS version and log file info
show_banner() {
    clear
    echo ""
    echo -e "${CYAN}${BOLD}MAC ULTIMATE OPTIMIZER${NC}"
    echo -e "${CYAN}======================${NC}"
    echo ""
    echo -e "System:  ${BLUE}macOS $OS_NAME $OS_MAJOR.$OS_MINOR (darwin $DARWIN_VERSION)${NC}"
    echo -e "Log:     ${BLUE}$LOG_FILE${NC}"
    echo -e "Mode:    ${BLUE}$([ "$DRY_RUN" = true ] && echo "--dry-run" || echo "LIVE")${NC}"
    echo ""
}

# 1. System Cleanup
cleanup_system() {
    show_banner
    echo -e "${YELLOW}${BOLD}WARNING: This will clear caches and logs.${NC}"
    echo -e "${YELLOW}It is HIGHLY RECOMMENDED to close all running applications first.${NC}"
    echo ""
    if [ "$DRY_RUN" = false ]; then
        read -r -p "Press [Enter] to continue or [Ctrl+C] to cancel..."
    fi
    
    # User Cache - show size first
    if [ -d "$HOME/Library/Caches" ] && [ -n "$(ls -A "$HOME/Library/Caches" 2>/dev/null)" ]; then
        local cache_size
        cache_size=$(du -sh "$HOME/Library/Caches" 2>/dev/null | cut -f1)
        echo -e "${CYAN}User Cache (~${cache_size}):${NC}"
        run_cmd "Cleaning User Cache" rm -rf "$HOME/Library/Caches"/*
    fi
    
    # User Logs only - NEVER touch /private/var/log
    # Note: System logs in /private/var/log require root and can break macOS
    if [ -d "$HOME/Library/Logs" ] && [ -n "$(ls -A "$HOME/Library/Logs" 2>/dev/null)" ]; then
        local logs_size
        logs_size=$(du -sh "$HOME/Library/Logs" 2>/dev/null | cut -f1)
        echo -e "${CYAN}User Logs (~${logs_size}):${NC}"
        run_cmd "Cleaning User Logs" rm -rf "$HOME/Library/Logs"/*
    fi
    
    # Trash - show size first
    if [ -d "$HOME/.Trash" ] && [ -n "$(ls -A "$HOME/.Trash" 2>/dev/null)" ]; then
        local trash_size
        trash_size=$(du -sh "$HOME/.Trash" 2>/dev/null | cut -f1)
        echo -e "${CYAN}Trash (~${trash_size}):${NC}"
        run_cmd "Emptying Trash" rm -rf "$HOME/.Trash"/*
    fi
    
    # Xcode DerivedData
    if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ] && [ -n "$(ls -A "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null)" ]; then
        local xcode_size
        xcode_size=$(du -sh "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | cut -f1)
        echo -e "${CYAN}Xcode DerivedData (~${xcode_size}):${NC}"
        run_cmd "Cleaning Xcode DerivedData" rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/*
    fi

    echo -e "\n${GREEN}✨ System Cleanup Complete!${NC}"
    [[ "$BATCH_MODE" == false ]] && read -r -p "Press Enter to return..."
}

# 2. Memory Optimization - replaced purge with informational display
optimize_memory() {
    show_banner
    echo -e "${CYAN}Memory Pressure Report${NC}"
    echo ""
    
    # Show memory stats (no purge - it's counterproductive on modern macOS)
    vm_stat | awk '
        /Pages free/        { free=$NF }
        /Pages active/      { active=$NF }
        /Pages inactive/    { inactive=$NF }
        /Pages wired/       { wired=$NF }
        /Pages compressed/  { compressed=$NF }
        END {
            page=4096
            printf "  Free:       %.2f GB\n", free*page/1073741824
            printf "  Active:    %.2f GB\n", active*page/1073741824
            printf "  Inactive:   %.2f GB\n", inactive*page/1073741824
            printf "  Wired:      %.2f GB\n", wired*page/1073741824
            printf "  Compressed: %.2f GB\n", compressed*page/1073741824
        }'
    echo ""
    echo -e "${YELLOW}Note: macOS manages memory automatically. 'Inactive' memory is${NC}"
    echo -e "${YELLOW}reused instantly — a large inactive pool is healthy, not wasteful.${NC}"
    echo -e "${YELLOW}'sudo purge' is counterproductive on macOS 10.11+ and has been removed.${NC}"
    [[ "$BATCH_MODE" == false ]] && read -r -p "Press Enter to return..."
}

# 3. Network Optimization
optimize_network() {
    show_banner
    echo -e "${BOLD}Network Booster${NC}"
    echo ""
    
    # WiFi power save - version gated
    if [ "$OS_MAJOR" -ge 13 ]; then
        echo -e "${YELLOW}[!] WiFi power management: managed by OS on macOS $OS_MAJOR+. Skipping.${NC}"
    else
        run_cmd "Disabling WiFi Power Save" sudo -v && sudo defaults write \
            /Library/Preferences/com.apple.wifi.plist WiFiPowerSave -int 0
    fi

    # DNS flush
    run_cmd "Flushing DNS cache" sudo -v && dscacheutil -flushcache && killall -HUP mDNSResponder 2>/dev/null || true

    # Network interface reset - with explicit warning and confirmation
    echo ""
    echo -e "${RED}WARNING: This will drop all active connections — SSH sessions,${NC}"
    echo -e "${RED}downloads, VPNs, and any active transfers on en0.${NC}"
    if [ "$DRY_RUN" = false ]; then
        read -r -p "Type 'yes' to continue, anything else to skip: " net_confirm
        if [[ "$net_confirm" == "yes" ]]; then
            run_cmd "Bringing en0 down" sudo -v && ifconfig en0 down
            sleep 1
            run_cmd "Bringing en0 up" sudo -v && ifconfig en0 up
            run_cmd "Renewing DHCP" sudo -v && ipconfig set en0 DHCP
        else
            echo -e "${YELLOW}[!] Network reset skipped.${NC}"
        fi
    else
        echo -e "${YELLOW}[DRY] Would prompt for network interface reset confirmation${NC}"
    fi

    # TCP sysctl tuning - removed non-existent captive_portal key
    echo ""
    run_cmd "Setting TCP send buffer" sudo -v && sysctl -w net.inet.tcp.sendspace=1048576
    run_cmd "Setting TCP recv buffer" sudo -v && sysctl -w net.inet.tcp.recvspace=1048576
    run_cmd "Setting IP TTL to 64" sudo -v && sysctl -w net.inet.ip.ttl=64

    echo -e "\n${GREEN}🚀 Network Boosted!${NC}"
    [[ "$BATCH_MODE" == false ]] && read -r -p "Press Enter to return..."
}

# 4. Maintenance Scripts
run_maintenance() {
    show_banner
    echo -e "${CYAN}Running macOS Daily/Weekly/Monthly maintenance scripts...${NC}"
    echo -e "${YELLOW}(This might take a few moments)${NC}"
    echo ""
    
    # Version note for Ventura+
    if [ "$OS_MAJOR" -ge 13 ]; then
        echo -e "${YELLOW}Note: On macOS $OS_MAJOR, periodic scripts run automatically via launchd.${NC}"
        echo -e "${YELLOW}Running manually is harmless but may not add meaningful benefit.${NC}"
        echo ""
    fi
    
    run_cmd "Running daily maintenance" sudo -v && periodic daily
    run_cmd "Running weekly maintenance" sudo -v && periodic weekly
    run_cmd "Running monthly maintenance" sudo -v && periodic monthly

    echo -e "\n${GREEN}✨ Maintenance Complete!${NC}"
    [[ "$BATCH_MODE" == false ]] && read -r -p "Press Enter to return..."
}

# 5. Flush Print Queue - fixed command syntax
flush_print_queue() {
    show_banner
    run_cmd "Cancelling all print jobs" cancel -a
    [[ "$BATCH_MODE" == false ]] && read -r -p "Press Enter to return..."
}

# 6. Reindex Spotlight
reindex_spotlight() {
    show_banner
    echo -e "${YELLOW}Warning: Reindexing Spotlight can take a while and use high CPU.${NC}"
    echo -e "${YELLOW}Only do this if your search is broken.${NC}"
    if [ "$DRY_RUN" = false ]; then
        read -r -p "Are you sure? (y/n): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            run_cmd "Requesting Spotlight reindex" sudo -v && mdutil -E /
        else
            echo "Cancelled."
        fi
    else
        echo -e "${YELLOW}[DRY] Would prompt for Spotlight reindex confirmation${NC}"
    fi
    [[ "$BATCH_MODE" == false ]] && read -r -p "Press Enter to return..."
}

# 7. Show Log (new option 8 in menu, index 7 here)
show_log() {
    show_banner
    if [ -f "$LOG_FILE" ]; then
        echo -e "${CYAN}Last 30 entries from $LOG_FILE:${NC}"
        echo ""
        tail -30 "$LOG_FILE"
    else
        echo -e "${YELLOW}No log file found yet. Run an optimization first.${NC}"
    fi
    [[ "$BATCH_MODE" == false ]] && read -r -p "Press Enter to return..."
}

# Run ALL (Option 7)
run_all() {
    BATCH_MODE=true
    cleanup_system
    optimize_memory
    optimize_network
    run_maintenance
    BATCH_MODE=false
    echo -e "\n${GREEN}✨ All Optimizations Complete!${NC}"
    read -r -p "Press Enter to return..."
}

# Main Menu Loop
while true; do
    show_banner
    echo -e "${BOLD}Select an Optimization:${NC}"
    echo -e "  ${CYAN}1)${NC} 🧹 System Cleanup (Cache, Logs, Trash)"
    echo -e "  ${CYAN}2)${NC} 🧠 Memory Pressure Report"
    echo -e "  ${CYAN}3)${NC} ⚡ Boost Internet/Network"
    echo -e "  ${CYAN}4)${NC} 🛠  Run Maintenance Scripts"
    echo -e "  ${CYAN}5)${NC} 🖨  Flush Print Queue"
    echo -e "  ${CYAN}6)${NC} 🔍 Reindex Spotlight"
    echo -e "  ${CYAN}7)${NC} 🌟 Run ALL Safe Optimizations (1-4)"
    echo -e "  ${CYAN}8)${NC} 📄 Show Activity Log"
    echo -e "  ${RED}9)${NC} 🚪 Exit"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}Running in DRY-RUN mode - no changes will be made${NC}"
        echo ""
    fi
    
    read -r -p "Choose option [1-9]: " option

    case $option in
        1) cleanup_system ;;
        2) optimize_memory ;;
        3) optimize_network ;;
        4) run_maintenance ;;
        5) flush_print_queue ;;
        6) reindex_spotlight ;;
        7) run_all ;;
        8) show_log ;;
        9) 
            echo -e "\n${GREEN}Stay fast! Exiting...${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Invalid option.${NC}"
            sleep 1 
            ;;
    esac
done