#!/bin/bash
# macOS Ultimate Optimizer v2.1.0
# ========================================================
set -euo pipefail

# ── Colours ──────────────────────────────────────────────
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Globals ───────────────────────────────────────────────
SCRIPT_VERSION="2.1.0"
DRY_RUN=false
BACKUP_MODE=false
AUTO_CONFIRM=false
BATCH_MODE=false
LOG_FILE="$HOME/.mac_optimizer.log"
BACKUP_DIR=""

# ── macOS version ─────────────────────────────────────────
OS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
OS_MINOR=$(sw_vers -productVersion | cut -d. -f2)
OS_NAME=$(sw_vers -productName)

# ── Argument parsing ──────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --backup)   BACKUP_MODE=true ;;
    --yes|-y)   AUTO_CONFIRM=true ;;
    --version)  echo "mac_optimizer v${SCRIPT_VERSION}"; exit 0 ;;
    --help)
      cat <<EOF
mac_optimizer v${SCRIPT_VERSION}
Usage: ./mac_optimizer.sh [OPTIONS]

Options:
  --dry-run    Preview all actions without making changes
  --backup     Move files to /tmp backup instead of deleting
  --yes, -y    Auto-confirm all prompts (for automation/cron)
  --version    Show version and exit
  --help       Show this help and exit
EOF
      exit 0 ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────
confirm() {
  # Usage: confirm "prompt text"
  # Skipped entirely when AUTO_CONFIRM=true
  [[ "$AUTO_CONFIRM" == true ]] && return 0
  read -r -p "$1"
}

confirm_yn() {
  # Usage: confirm_yn "prompt" && do_thing
  # Returns 0 (yes) automatically when AUTO_CONFIRM=true
  if [[ "$AUTO_CONFIRM" == true ]]; then return 0; fi
  local ans
  read -r -p "$1 (y/n): " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

log_action() {
  local desc="$1"
  local status="$2"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$([ "$status" -eq 0 ] && echo OK || echo FAIL)] $desc" >> "$LOG_FILE"
  # Rotate if over 500 KB
  local size
  size=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
  if [[ "$size" -gt 512000 ]]; then
    mv "$LOG_FILE" "${LOG_FILE}.1"
  fi
}

require_min_version() {
  local min_major=$1
  if [[ "$OS_MAJOR" -lt "$min_major" ]]; then
    echo -e "${YELLOW}[!] Skipped — requires macOS ${min_major}+${NC}"
    return 1
  fi
  return 0
}

spinner() {
  local pid=$1
  local spinstr
  spinstr=$(printf '|/-\\')
  while kill -0 "$pid" 2>/dev/null; do
    printf " [%c] " "$spinstr"
    spinstr=${spinstr#?}${spinstr%"${spinstr#?}"}
    sleep 0.1
    printf "\b\b\b\b\b\b"
  done
  printf "      \b\b\b\b\b\b"
}

run_cmd() {
  local desc="$1"; shift
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${CYAN}→ ${desc}...${NC} ${YELLOW}[DRY] would run: $*${NC}"
    return 0
  fi
  echo -ne "${CYAN}→ ${desc}...${NC}"
  if "$@" > /tmp/mac_opt_last.log 2>&1; then
    echo -e " ${GREEN}[✔]${NC}"
    log_action "$desc" 0
  else
    echo -e " ${RED}[✘] (see /tmp/mac_opt_last.log)${NC}"
    log_action "$desc" 1
  fi
}

# Move or delete a directory's contents, respecting --backup
clean_dir() {
  local label="$1"
  local path="$2"
  if [[ ! -d "$path" ]] || [[ -z "$(ls -A "$path" 2>/dev/null)" ]]; then
    return 0
  fi
  local size
  size=$(du -sh "$path" 2>/dev/null | cut -f1)
  echo -e "${CYAN}${label} (~${size}):${NC}"
  if [[ "$BACKUP_MODE" == true ]]; then
    run_cmd "Backing up ${label}" cp -r "$path" "${BACKUP_DIR}/${label// /_}"
    run_cmd "Clearing ${label}" find "$path" -mindepth 1 -delete
  else
    run_cmd "Clearing ${label}" find "$path" -mindepth 1 -delete
  fi
}

show_banner() {
  clear
  echo ""
  echo -e "${CYAN}${BOLD}MAC ULTIMATE OPTIMIZER v${SCRIPT_VERSION}${NC}"
  echo -e "${CYAN}======================================${NC}"
  echo ""
  echo -e "System : ${BLUE}${OS_NAME} ${OS_MAJOR}.${OS_MINOR}${NC}"
  echo -e "Log    : ${BLUE}${LOG_FILE}${NC}"
  local mode_str="LIVE"
  [[ "$DRY_RUN"    == true ]] && mode_str="DRY-RUN"
  [[ "$BACKUP_MODE" == true ]] && mode_str="${mode_str} + BACKUP"
  [[ "$AUTO_CONFIRM" == true ]] && mode_str="${mode_str} + AUTO-YES"
  echo -e "Mode   : ${BLUE}${mode_str}${NC}"
  echo ""
}

# ── 1. System Cleanup ─────────────────────────────────────
cleanup_system() {
  show_banner
  echo -e "${YELLOW}${BOLD}WARNING: This will clear caches, logs and trash.${NC}"
  echo -e "${YELLOW}Close all running applications first.${NC}"
  echo ""

  if [[ "$BACKUP_MODE" == true && "$DRY_RUN" == false ]]; then
    BACKUP_DIR="/tmp/mac_optimizer_backup_$(date +%s)"
    mkdir -p "$BACKUP_DIR"
    echo -e "${CYAN}Backup destination: ${BACKUP_DIR}${NC}\n"
  fi

  confirm "Press [Enter] to continue or [Ctrl+C] to cancel... "

  # Capture disk free before
  local before_kb after_kb freed_mb
  before_kb=$(df -k / | awk 'NR==2{print $4}')

  clean_dir "User Cache"       "$HOME/Library/Caches"
  clean_dir "User Logs"        "$HOME/Library/Logs"
  clean_dir "Trash"            "$HOME/.Trash"
  clean_dir "Xcode DerivedData" "$HOME/Library/Developer/Xcode/DerivedData"

  # App-specific caches
  echo -e "\n${CYAN}${BOLD}App Caches:${NC}"
  clean_dir "Chrome"     "$HOME/Library/Caches/Google/Chrome"
  clean_dir "Chromium"   "$HOME/Library/Caches/Chromium"
  clean_dir "Docker VMs" "$HOME/Library/Containers/com.docker.docker/Data/vms"
  clean_dir "npm"        "$HOME/.npm/_cacache"
  clean_dir "Yarn"       "$HOME/Library/Caches/Yarn"
  clean_dir "pip"        "$HOME/Library/Caches/pip"
  clean_dir "CocoaPods"  "$HOME/Library/Caches/CocoaPods"
  clean_dir "Gradle"     "$HOME/.gradle/caches"

  # Disk freed summary
  after_kb=$(df -k / | awk 'NR==2{print $4}')
  freed_mb=$(( (after_kb - before_kb) / 1024 ))
  echo -e "\n${GREEN}✨ System Cleanup Complete! Freed approx. ${freed_mb} MB${NC}"

  [[ "$BATCH_MODE" == false ]] && confirm "Press Enter to return... "
}

# ── 2. Memory Report ──────────────────────────────────────
optimize_memory() {
  show_banner
  echo -e "${CYAN}${BOLD}Memory Pressure Report${NC}"
  echo ""

  vm_stat | awk '
    /Pages free/       { free=$NF }
    /Pages active/     { active=$NF }
    /Pages inactive/   { inactive=$NF }
    /Pages wired/      { wired=$NF }
    /Pages compressed/ { compressed=$NF }
    END {
      page=4096
      printf "  Free:       %.2f GB\n", free*page/1073741824
      printf "  Active:     %.2f GB\n", active*page/1073741824
      printf "  Inactive:   %.2f GB\n", inactive*page/1073741824
      printf "  Wired:      %.2f GB\n", wired*page/1073741824
      printf "  Compressed: %.2f GB\n", compressed*page/1073741824
    }'

  echo ""
  echo -e "${CYAN}${BOLD}Top 5 processes by memory (RSS):${NC}"
  printf "  %-8s %-10s %s\n" "PID" "RSS (MB)" "COMMAND"
  printf "  %-8s %-10s %s\n" "---" "--------" "-------"
  ps -eo pid,rss,comm -r 2>/dev/null | awk 'NR>1 && NR<=6 {
    printf "  %-8s %-10s %s\n", $1, int($2/1024), $3
  }'

  echo ""
  echo -e "${YELLOW}Note: macOS manages memory automatically. A large 'Inactive'${NC}"
  echo -e "${YELLOW}pool is healthy — it is reused instantly when needed.${NC}"
  echo -e "${YELLOW}'sudo purge' is counterproductive on macOS 10.11+ and is not used.${NC}"

  [[ "$BATCH_MODE" == false ]] && confirm "Press Enter to return... "
}

# ── 3. Network Booster ────────────────────────────────────
optimize_network() {
  show_banner
  echo -e "${BOLD}Network Booster${NC}"
  echo ""

  # Require sudo once up front
  sudo -v || { echo -e "${RED}sudo authentication failed.${NC}"; return 1; }

  # WiFi power save — version gated
  if [[ "$OS_MAJOR" -ge 13 ]]; then
    echo -e "${YELLOW}[!] WiFi power management is handled by the OS on macOS ${OS_MAJOR}+. Skipping.${NC}"
  else
    run_cmd "Disabling WiFi Power Save" \
      sudo defaults write /Library/Preferences/com.apple.wifi.plist WiFiPowerSave -int 0
  fi

  # DNS flush
  run_cmd "Flushing DNS cache"        sudo dscacheutil -flushcache
  run_cmd "Restarting mDNSResponder"  sudo killall -HUP mDNSResponder

  # Network interface reset
  echo ""
  echo -e "${RED}WARNING: Resetting en0 will drop all active connections${NC}"
  echo -e "${RED}(SSH, VPNs, downloads). Skip if you are on a remote session.${NC}"
  if confirm_yn "Reset network interface en0?"; then
    run_cmd "Bringing en0 down" sudo ifconfig en0 down
    sleep 1
    run_cmd "Bringing en0 up"   sudo ifconfig en0 up
    run_cmd "Renewing DHCP"     sudo ipconfig set en0 DHCP
  else
    echo -e "${YELLOW}[!] Network interface reset skipped.${NC}"
  fi

  # TCP sysctl tuning
  echo ""
  run_cmd "Setting TCP send buffer" sudo sysctl -w net.inet.tcp.sendspace=1048576
  run_cmd "Setting TCP recv buffer" sudo sysctl -w net.inet.tcp.recvspace=1048576
  run_cmd "Setting IP TTL to 64"    sudo sysctl -w net.inet.ip.ttl=64

  echo -e "${YELLOW}[!] sysctl changes are TEMPORARY and reset on reboot.${NC}"
  echo -e "${YELLOW}    To persist them, add the values to /etc/sysctl.conf${NC}"

  echo -e "\n${GREEN}Network Boosted!${NC}"
  [[ "$BATCH_MODE" == false ]] && confirm "Press Enter to return... "
}

# ── 4. Maintenance Scripts ────────────────────────────────
run_maintenance() {
  show_banner
  echo -e "${CYAN}Running macOS Daily/Weekly/Monthly maintenance scripts...${NC}"
  echo -e "${YELLOW}(This may take several minutes)${NC}"
  echo ""

  sudo -v || { echo -e "${RED}sudo authentication failed.${NC}"; return 1; }

  if [[ "$OS_MAJOR" -ge 12 ]]; then
    echo -e "${YELLOW}Note: On macOS ${OS_MAJOR}, periodic scripts run automatically via launchd.${NC}"
    echo -e "${YELLOW}Running manually is harmless but may not add meaningful benefit.${NC}"
    echo ""
  fi

  if [[ "$DRY_RUN" == false ]]; then
    echo -ne "${CYAN}→ Running daily maintenance...${NC}"
    sudo periodic daily > /tmp/mac_opt_last.log 2>&1 &
    spinner $!; wait $!
    echo -e " ${GREEN}[✔]${NC}"; log_action "daily maintenance" 0

    echo -ne "${CYAN}→ Running weekly maintenance...${NC}"
    sudo periodic weekly >> /tmp/mac_opt_last.log 2>&1 &
    spinner $!; wait $!
    echo -e " ${GREEN}[✔]${NC}"; log_action "weekly maintenance" 0

    echo -ne "${CYAN}→ Running monthly maintenance...${NC}"
    sudo periodic monthly >> /tmp/mac_opt_last.log 2>&1 &
    spinner $!; wait $!
    echo -e " ${GREEN}[✔]${NC}"; log_action "monthly maintenance" 0
  else
    echo -e "${YELLOW}[DRY] would run: sudo periodic daily weekly monthly${NC}"
  fi

  echo -e "\n${GREEN}✨ Maintenance Complete!${NC}"
  [[ "$BATCH_MODE" == false ]] && confirm "Press Enter to return... "
}

# ── 5. Flush Print Queue ──────────────────────────────────
flush_print_queue() {
  show_banner
  run_cmd "Cancelling all print jobs" cancel -a || true
  [[ "$BATCH_MODE" == false ]] && confirm "Press Enter to return... "
}

# ── 6. Reindex Spotlight ──────────────────────────────────
reindex_spotlight() {
  show_banner
  echo -e "${YELLOW}Warning: Reindexing Spotlight takes time and spikes CPU.${NC}"
  echo -e "${YELLOW}Only do this if Spotlight search is broken.${NC}"

  if confirm_yn "Reindex Spotlight?"; then
    sudo -v || { echo -e "${RED}sudo authentication failed.${NC}"; return 1; }
    if [[ "$DRY_RUN" == false ]]; then
      echo -ne "${CYAN}→ Requesting Spotlight reindex...${NC}"
      sudo mdutil -E / > /tmp/mac_opt_last.log 2>&1 &
      spinner $!; wait $!
      echo -e " ${GREEN}[✔]${NC}"
      log_action "Spotlight reindex" 0
    else
      echo -e "${YELLOW}[DRY] would run: sudo mdutil -E /${NC}"
    fi
  else
    echo "Cancelled."
  fi

  [[ "$BATCH_MODE" == false ]] && confirm "Press Enter to return... "
}

# ── 7. Run ALL ────────────────────────────────────────────
run_all() {
  BATCH_MODE=true
  { cleanup_system && optimize_memory && optimize_network && run_maintenance; } || true
  BATCH_MODE=false
  echo -e "\n${GREEN}✨ All Optimizations Complete!${NC}"
  confirm "Press Enter to return... "
}

# ── 8. Show Log ───────────────────────────────────────────
show_log() {
  show_banner
  if [[ -f "$LOG_FILE" ]]; then
    echo -e "${CYAN}Last 30 entries from ${LOG_FILE}:${NC}"
    echo ""
    tail -30 "$LOG_FILE"
  else
    echo -e "${YELLOW}No log file yet. Run an optimization first.${NC}"
  fi
  [[ "$BATCH_MODE" == false ]] && confirm "Press Enter to return... "
}

# ── Main Menu ─────────────────────────────────────────────
while true; do
  show_banner
  echo -e "${BOLD}Select an Optimization:${NC}"
  echo -e " ${CYAN}1)${NC} System Cleanup (Cache, Logs, Trash + App Caches)"
  echo -e " ${CYAN}2)${NC} Memory Pressure Report"
  echo -e " ${CYAN}3)${NC} Boost Internet/Network"
  echo -e " ${CYAN}4)${NC} Run Maintenance Scripts"
  echo -e " ${CYAN}5)${NC} Flush Print Queue"
  echo -e " ${CYAN}6)${NC} Reindex Spotlight"
  echo -e " ${CYAN}7)${NC} Run ALL Safe Optimizations (1-4)"
  echo -e " ${CYAN}8)${NC} Show Activity Log"
  echo -e " ${RED}9)${NC} Exit"
  echo ""
  [[ "$DRY_RUN" == true ]] && echo -e "${YELLOW}DRY-RUN mode — no changes will be made${NC}\n"

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
    9) echo -e "\n${GREEN}Stay fast! Exiting...${NC}"; exit 0 ;;
    *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
  esac
done