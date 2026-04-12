#!/bin/bash

# macOS Ultimate Optimizer v2.1.0 — Production Quality
# ======================================================

set -euo pipefail

# ── Colors & Styles ──────────────────────────────────────────────────────────
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Global State ─────────────────────────────────────────────────────────────
SCRIPT_VERSION="2.1.0"
DRY_RUN=false
BATCH_MODE=false
AUTO_CONFIRM=false
BACKUP_MODE=false
LOG_FILE="$HOME/.mac_optimizer.log"

# ── Detect macOS version ────────────────────────────────────────────────────
OS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
OS_MINOR=$(sw_vers -productVersion | cut -d. -f2)
OS_NAME=$(sw_vers -productName)

# ── Version gating helper ───────────────────────────────────────────────────
require_min_version() {
    local min_major="$1"
    if [[ "$OS_MAJOR" -lt "$min_major" ]]; then
        echo -e "${YELLOW}[!] Skipped — requires macOS ${min_major}+${NC}"
        return 1
    fi
    return 0
}

# ── Help ─────────────────────────────────────────────────────────────────────
show_help() {
    echo "mac_optimizer v${SCRIPT_VERSION}"
    echo "Usage: ./mac_optimizer.sh [OPTIONS]"
    echo "Options:"
    echo "  --dry-run    Preview all actions without making changes"
    echo "  --backup     Move files to /tmp backup instead of deleting"
    echo "  --yes, -y    Auto-confirm all prompts (for automation/cron)"
    echo "  --version    Show version and exit"
    echo "  --help       Show this help and exit"
}

# ── Parse flags ──────────────────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --dry-run)  DRY_RUN=true ;;
        --yes|-y)   AUTO_CONFIRM=true ;;
        --backup)   BACKUP_MODE=true ;;
        --help)     show_help; exit 0 ;;
        --version)  echo "mac_optimizer v${SCRIPT_VERSION}"; exit 0 ;;
        *)          echo "Unknown option: $arg"; show_help; exit 1 ;;
    esac
done

# ── Minimum macOS gate ───────────────────────────────────────────────────────
require_min_version 12 || { echo "This script requires macOS 12 or later."; exit 1; }

# ── Logging with rotation ───────────────────────────────────────────────────
log_action() {
    local desc="$1"
    local status="$2"
    local label
    if [[ "$status" -eq 0 ]]; then label="OK"; else label="FAIL"; fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$label] $desc" >> "$LOG_FILE"

    # Rotate if over 500 KB
    local size
    size=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
    if [[ "$size" -gt 512000 ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.1"
    fi
}

# ── Spinner for long-running operations ──────────────────────────────────────
spinner() {
    local pid="$1"
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        case $((i % 4)) in
            0) printf "\b|" ;;
            1) printf "\b/" ;;
            2) printf "\b-" ;;
            3) printf "\b\\" ;;
        esac
        i=$((i + 1))
        sleep 0.1
    done
    printf "\b"
}

# ── run_cmd — execute + log + display status ─────────────────────────────────
run_cmd() {
    local desc="$1"; shift
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${CYAN}→ ${desc}...${NC} ${YELLOW}[DRY] would run: $*${NC}"
        return 0
    fi
    echo -ne "${CYAN}→ ${desc}...${NC}"
    local status=0
    "$@" > /tmp/mac_opt_last.log 2>&1 || status=$?
    if [[ $status -eq 0 ]]; then
        echo -e " ${GREEN}[✔]${NC}"
    else
        echo -e " ${RED}[✘] (see /tmp/mac_opt_last.log)${NC}"
    fi
    log_action "$desc" "$status"
    return "$status"
}

# ── run_cmd_spinner — run_cmd with spinner for long ops ──────────────────────
run_cmd_spinner() {
    local desc="$1"; shift
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${CYAN}→ ${desc}...${NC} ${YELLOW}[DRY] would run: $*${NC}"
        return 0
    fi
    echo -ne "${CYAN}→ ${desc}... ${NC}"
    "$@" > /tmp/mac_opt_last.log 2>&1 &
    local pid=$!
    spinner "$pid"
    local status=0
    wait "$pid" 2>/dev/null || status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}[✔]${NC}"
    else
        echo -e "${RED}[✘] (see /tmp/mac_opt_last.log)${NC}"
    fi
    log_action "$desc" "$status"
    return "$status"
}

# ── Banner ───────────────────────────────────────────────────────────────────
show_banner() {
    clear
    echo ""
    echo -e "${CYAN}${BOLD}MAC ULTIMATE OPTIMIZER v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}====================================${NC}"
    echo ""
    echo -e "System:  ${BLUE}${OS_NAME} ${OS_MAJOR}.${OS_MINOR}${NC}"
    echo -e "Log:     ${BLUE}${LOG_FILE}${NC}"
    local mode_label
    if [[ "$DRY_RUN" == true ]]; then mode_label="--dry-run"; else mode_label="LIVE"; fi
    if [[ "$BACKUP_MODE" == true ]]; then mode_label="${mode_label} + --backup"; fi
    if [[ "$AUTO_CONFIRM" == true ]]; then mode_label="${mode_label} + --yes"; fi
    echo -e "Mode:    ${BLUE}${mode_label}${NC}"
    echo ""
}

# ── Helper: clean a directory respecting --dry-run and --backup ──────────────
clean_dir() {
    local label="$1"
    local target="$2"
    local backup_dir="$3"

    if [[ "$DRY_RUN" == true ]]; then
        run_cmd "Cleaning ${label}" find "$target" -mindepth 1 -print || true
    elif [[ "$BACKUP_MODE" == true ]] && [[ -n "$backup_dir" ]]; then
        run_cmd "Backing up ${label}" find "$target" -mindepth 1 -maxdepth 1 \
            -exec mv {} "$backup_dir/" \; || true
    else
        run_cmd "Cleaning ${label}" find "$target" -mindepth 1 -delete || true
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 1. System Cleanup
# ════════════════════════════════════════════════════════════════════════════
cleanup_system() {
    show_banner
    echo -e "${YELLOW}${BOLD}WARNING: This will clear caches and logs.${NC}"
    echo -e "${YELLOW}It is HIGHLY RECOMMENDED to close all running applications first.${NC}"
    echo ""
    if [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == false ]]; then
        read -r -p "Press [Enter] to continue or [Ctrl+C] to cancel..."
    elif [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == true ]]; then
        echo -e "${YELLOW}[AUTO-CONFIRM] Proceeding with cleanup...${NC}"
    fi

    # Setup backup directory if --backup flag is used
    local backup_dir=""
    if [[ "$BACKUP_MODE" == true ]]; then
        backup_dir="/tmp/mac_optimizer_backup_$(date +%s)"
        mkdir -p "$backup_dir"
        echo -e "${CYAN}Backup mode: Files will be moved to ${backup_dir}${NC}"
    fi

    # ── Capture disk space BEFORE cleanup (KB for math, human for display) ──
    local before_free_kb before_free_h
    before_free_kb=$(df -k / | awk 'NR==2{print $4}')
    before_free_h=$(df -h / | awk 'NR==2{print $4}')

    # ── User Cache ───────────────────────────────────────────────────────────
    if [[ -d "$HOME/Library/Caches" ]] && [[ -n "$(ls -A "$HOME/Library/Caches" 2>/dev/null)" ]]; then
        local cache_size
        cache_size=$(du -sh "$HOME/Library/Caches" 2>/dev/null | cut -f1)
        echo -e "${CYAN}User Cache (~${cache_size}):${NC}"
        clean_dir "User Cache" "$HOME/Library/Caches" "$backup_dir"
    fi

    # ── User Logs (NEVER touch /private/var/log) ─────────────────────────────
    if [[ -d "$HOME/Library/Logs" ]] && [[ -n "$(ls -A "$HOME/Library/Logs" 2>/dev/null)" ]]; then
        local logs_size
        logs_size=$(du -sh "$HOME/Library/Logs" 2>/dev/null | cut -f1)
        echo -e "${CYAN}User Logs (~${logs_size}):${NC}"
        clean_dir "User Logs" "$HOME/Library/Logs" "$backup_dir"
    fi

    # ── Trash ────────────────────────────────────────────────────────────────
    if [[ -d "$HOME/.Trash" ]] && [[ -n "$(ls -A "$HOME/.Trash" 2>/dev/null)" ]]; then
        local trash_size
        trash_size=$(du -sh "$HOME/.Trash" 2>/dev/null | cut -f1)
        echo -e "${CYAN}Trash (~${trash_size}):${NC}"
        clean_dir "Trash" "$HOME/.Trash" "$backup_dir"
    fi

    # ── Xcode DerivedData ────────────────────────────────────────────────────
    if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]] && \
       [[ -n "$(ls -A "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null)" ]]; then
        local xcode_size
        xcode_size=$(du -sh "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | cut -f1)
        echo -e "${CYAN}Xcode DerivedData (~${xcode_size}):${NC}"
        clean_dir "Xcode DerivedData" "$HOME/Library/Developer/Xcode/DerivedData" "$backup_dir"
    fi

    # ── App-specific cache cleaning ──────────────────────────────────────────
    echo ""
    echo -e "${BOLD}App Caches:${NC}"
    local app_caches=(
        "Google Chrome:$HOME/Library/Caches/Google/Chrome"
        "Chromium:$HOME/Library/Caches/Chromium"
        "Docker:$HOME/Library/Containers/com.docker.docker/Data/vms"
        "npm:$HOME/.npm/_cacache"
        "Yarn:$HOME/Library/Caches/Yarn"
        "pip:$HOME/Library/Caches/pip"
        "CocoaPods:$HOME/Library/Caches/CocoaPods"
        "Gradle:$HOME/.gradle/caches"
    )

    local app_name cache_path app_cache_size
    for cache_pair in "${app_caches[@]}"; do
        IFS=':' read -r app_name cache_path <<< "$cache_pair"
        if [[ -d "$cache_path" ]] && [[ -n "$(ls -A "$cache_path" 2>/dev/null)" ]]; then
            app_cache_size=$(du -sh "$cache_path" 2>/dev/null | cut -f1)
            echo -e "${CYAN}  ${app_name} Cache (~${app_cache_size}):${NC}"
            clean_dir "${app_name} Cache" "$cache_path" "$backup_dir"
        fi
    done

    # ── Capture disk space AFTER cleanup ─────────────────────────────────────
    local after_free_kb after_free_h freed_mb
    after_free_kb=$(df -k / | awk 'NR==2{print $4}')
    after_free_h=$(df -h / | awk 'NR==2{print $4}')
    freed_mb=$(( (after_free_kb - before_free_kb) / 1024 ))

    echo ""
    echo -e "${GREEN}✨ System Cleanup Complete!${NC}"
    echo -e "${GREEN}Freed approx. ${freed_mb} MB — disk was ${before_free_h}, now ${after_free_h}${NC}"

    if [[ "$BATCH_MODE" == false ]]; then
        if [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == false ]]; then
            read -r -p "Press Enter to return..."
        elif [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == true ]]; then
            echo -e "${YELLOW}[AUTO-CONFIRM] Continuing...${NC}"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 2. Memory Pressure Report
# ════════════════════════════════════════════════════════════════════════════
optimize_memory() {
    show_banner
    echo -e "${CYAN}Memory Pressure Report${NC}"
    echo ""

    # Show memory stats (no purge — counterproductive on modern macOS)
    vm_stat | awk '
        /Pages free/        { free=$NF }
        /Pages active/      { active=$NF }
        /Pages inactive/    { inactive=$NF }
        /Pages wired/       { wired=$NF }
        /Pages compressed/  { compressed=$NF }
        END {
            page=4096
            printf "  Free:       %.2f GB\n", free*page/1073741824
            printf "  Active:     %.2f GB\n", active*page/1073741824
            printf "  Inactive:   %.2f GB\n", inactive*page/1073741824
            printf "  Wired:      %.2f GB\n", wired*page/1073741824
            printf "  Compressed: %.2f GB\n", compressed*page/1073741824
        }'
    echo ""
    echo -e "${YELLOW}Note: macOS manages memory automatically. 'Inactive' memory is${NC}"
    echo -e "${YELLOW}reused instantly — a large inactive pool is healthy, not wasteful.${NC}"
    echo -e "${YELLOW}'sudo purge' is counterproductive on macOS 10.11+ and has been removed.${NC}"

    # ── Top 5 RAM-consuming processes ────────────────────────────────────────
    echo ""
    echo -e "${CYAN}Top 5 processes by memory (RSS):${NC}"
    printf "  %-8s %-10s %s\n" "PID" "RSS (MB)" "COMMAND"
    ps -eo pid,rss,comm -r 2>/dev/null | awk 'NR>1 && NR<=6 {
        printf "  %-8s %-10s %s\n", $1, int($2/1024), $3
    }'

    if [[ "$BATCH_MODE" == false ]]; then
        if [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == false ]]; then
            read -r -p "Press Enter to return..."
        elif [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == true ]]; then
            echo -e "${YELLOW}[AUTO-CONFIRM] Continuing...${NC}"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 3. Network Optimization
# ════════════════════════════════════════════════════════════════════════════
optimize_network() {
    show_banner
    echo -e "${BOLD}Network Booster${NC}"
    echo ""

    # Require sudo once at the top
    sudo -v || { echo "sudo authentication failed"; return 1; }

    # WiFi power save — version gated
    if [[ "$OS_MAJOR" -ge 13 ]]; then
        echo -e "${YELLOW}[!] WiFi power management: managed by OS on macOS ${OS_MAJOR}+. Skipping.${NC}"
    else
        run_cmd "Disabling WiFi Power Save" sudo defaults write \
            /Library/Preferences/com.apple.wifi.plist WiFiPowerSave -int 0 || true
    fi

    # DNS flush
    run_cmd "Flushing DNS cache" dscacheutil -flushcache || true
    run_cmd "Restarting mDNSResponder" sudo killall -HUP mDNSResponder || true

    # Network interface reset — with explicit warning and confirmation
    echo ""
    echo -e "${RED}WARNING: This will drop all active connections — SSH sessions,${NC}"
    echo -e "${RED}downloads, VPNs, and any active transfers on en0.${NC}"
    if [[ "$DRY_RUN" == false ]]; then
        local net_confirm
        if [[ "$AUTO_CONFIRM" == true ]]; then
            net_confirm="yes"
            echo -e "${YELLOW}[AUTO-CONFIRM] Proceeding with network reset...${NC}"
        else
            read -r -p "Type 'yes' to continue, anything else to skip: " net_confirm
        fi
        if [[ "$net_confirm" == "yes" ]]; then
            run_cmd "Bringing en0 down" sudo ifconfig en0 down || true
            sleep 1
            run_cmd "Bringing en0 up" sudo ifconfig en0 up || true
            run_cmd "Renewing DHCP" sudo ipconfig set en0 DHCP || true
        else
            echo -e "${YELLOW}[!] Network reset skipped.${NC}"
        fi
    else
        echo -e "${YELLOW}[DRY] Would prompt for network interface reset confirmation${NC}"
    fi

    # TCP sysctl tuning
    echo ""
    run_cmd "Setting TCP send buffer" sudo sysctl -w net.inet.tcp.sendspace=1048576 || true
    run_cmd "Setting TCP recv buffer" sudo sysctl -w net.inet.tcp.recvspace=1048576 || true
    run_cmd "Setting IP TTL to 64" sudo sysctl -w net.inet.ip.ttl=64 || true

    # Warn that sysctl changes are temporary
    echo -e "${YELLOW}[!] sysctl changes above are TEMPORARY and will reset on reboot.${NC}"
    echo -e "${YELLOW}    To persist them, add the settings to /etc/sysctl.conf${NC}"

    echo -e "\n${GREEN}🚀 Network Boosted!${NC}"
    if [[ "$BATCH_MODE" == false ]]; then
        if [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == false ]]; then
            read -r -p "Press Enter to return..."
        elif [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == true ]]; then
            echo -e "${YELLOW}[AUTO-CONFIRM] Continuing...${NC}"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 4. Maintenance Scripts (with spinner)
# ════════════════════════════════════════════════════════════════════════════
run_maintenance() {
    show_banner
    echo -e "${CYAN}Running macOS Daily/Weekly/Monthly maintenance scripts...${NC}"
    echo -e "${YELLOW}(This might take a few moments)${NC}"
    echo ""

    # Version note for Monterey+
    if [[ "$OS_MAJOR" -ge 12 ]]; then
        echo -e "${YELLOW}Note: On macOS ${OS_MAJOR}, periodic scripts also run via launchd.${NC}"
        echo -e "${YELLOW}Running manually is harmless but may not add meaningful benefit.${NC}"
        echo ""
    fi

    sudo -v || { echo "sudo authentication failed"; return 1; }

    run_cmd_spinner "Running daily maintenance" sudo periodic daily || true
    run_cmd_spinner "Running weekly maintenance" sudo periodic weekly || true
    run_cmd_spinner "Running monthly maintenance" sudo periodic monthly || true

    echo -e "\n${GREEN}✨ Maintenance Complete!${NC}"
    if [[ "$BATCH_MODE" == false ]]; then
        if [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == false ]]; then
            read -r -p "Press Enter to return..."
        elif [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == true ]]; then
            echo -e "${YELLOW}[AUTO-CONFIRM] Continuing...${NC}"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 5. Flush Print Queue
# ════════════════════════════════════════════════════════════════════════════
flush_print_queue() {
    show_banner
    if ! cancel -a &>/dev/null; then
        sudo -v || { echo "sudo authentication failed"; return 1; }
        run_cmd "Cancelling all print jobs" sudo cancel -a || true
    else
        run_cmd "Cancelling all print jobs" cancel -a || true
    fi
    if [[ "$BATCH_MODE" == false ]]; then
        if [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == false ]]; then
            read -r -p "Press Enter to return..."
        elif [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == true ]]; then
            echo -e "${YELLOW}[AUTO-CONFIRM] Continuing...${NC}"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 6. Reindex Spotlight (with spinner)
# ════════════════════════════════════════════════════════════════════════════
reindex_spotlight() {
    show_banner
    echo -e "${YELLOW}Warning: Reindexing Spotlight can take a while and use high CPU.${NC}"
    echo -e "${YELLOW}Only do this if your search is broken.${NC}"
    if [[ "$DRY_RUN" == false ]]; then
        local choice
        if [[ "$AUTO_CONFIRM" == true ]]; then
            choice="y"
            echo -e "${YELLOW}[AUTO-CONFIRM] Proceeding with Spotlight reindex...${NC}"
        else
            read -r -p "Are you sure? (y/n): " choice
        fi
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            sudo -v || { echo "sudo authentication failed"; return 1; }
            run_cmd_spinner "Requesting Spotlight reindex" sudo mdutil -E / || true
        else
            echo "Cancelled."
        fi
    else
        echo -e "${YELLOW}[DRY] Would prompt for Spotlight reindex confirmation${NC}"
    fi
    if [[ "$BATCH_MODE" == false ]]; then
        if [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == false ]]; then
            read -r -p "Press Enter to return..."
        elif [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == true ]]; then
            echo -e "${YELLOW}[AUTO-CONFIRM] Continuing...${NC}"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 7. Show Activity Log
# ════════════════════════════════════════════════════════════════════════════
show_log() {
    show_banner
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${CYAN}Last 30 entries from ${LOG_FILE}:${NC}"
        echo ""
        tail -30 "$LOG_FILE"
    else
        echo -e "${YELLOW}No log file found yet. Run an optimization first.${NC}"
    fi
    if [[ "$BATCH_MODE" == false ]]; then
        if [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == false ]]; then
            read -r -p "Press Enter to return..."
        elif [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == true ]]; then
            echo -e "${YELLOW}[AUTO-CONFIRM] Continuing...${NC}"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 8. Run ALL (batch mode with safe BATCH_MODE reset)
# ════════════════════════════════════════════════════════════════════════════
run_all() {
    BATCH_MODE=true
    { cleanup_system && optimize_memory && optimize_network && run_maintenance; } || true
    BATCH_MODE=false
    echo -e "\n${GREEN}✨ All Optimizations Complete!${NC}"
    if [[ "$AUTO_CONFIRM" == false ]]; then
        read -r -p "Press Enter to return..."
    else
        echo -e "${YELLOW}[AUTO-CONFIRM] Continuing...${NC}"
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# Main Menu Loop
# ════════════════════════════════════════════════════════════════════════════
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

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}Running in DRY-RUN mode — no changes will be made${NC}"
        echo ""
    fi

    read -r -p "Choose option [1-9]: " option

    case "$option" in
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