# macOS Ultimate Optimizer

[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![macOS](https://img.shields.io/badge/Supported-macOS%2012--15-Monterey%20to%20Sequoia-333333?style=for-the-badge)](#compatibility)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-Pass-green?style=for-the-badge)](#code-quality)

> A production-quality macOS system optimization and maintenance script for power users and system administrators.

---

## Description

**macOS Ultimate Optimizer** is a menu-driven Bash script that safely cleans caches, manages memory, optimizes network settings, and runs macOS maintenance scripts on your Mac. Designed for macOS Monterey (12), Ventura (13), Sonoma (14), and Sequoia (15).

### What makes it production-quality?

- **Correct exit codes** — Every command's real exit status is captured and logged
- **Activity logging** — All actions recorded with timestamps to `~/.mac_optimizer.log`
- **Dry-run mode** — Test without making changes using `--dry-run`
- **Version gating** — Automatically skips incompatible operations per macOS version
- **Safe by design** — Never touches `/private/var/log` or uses `sudo purge`
- **ShellCheck verified** — Passes with zero warnings or errors

---

## Features

| # | Feature | Description |
|---|---------|-------------|
| 1 | **System Cleanup** | Clears user caches, logs, trash, and Xcode DerivedData (shows size before deleting). |
| 2 | **Memory Pressure Report** | Displays VM statistics (Free, Active, Inactive, Wired, Compressed) — replaces counterproductive `purge`. |
| 3 | **Network Booster** | Flushes DNS, configures TCP buffers, resets interface with confirmation. |
| 4 | **Maintenance Scripts** | Manually runs daily/weekly/monthly periodic scripts. |
| 5 | **Flush Print Queue** | Cancels all stuck print jobs. |
| 6 | **Reindex Spotlight** | Rebuilds Spotlight search index. |
| 7 | **Run ALL** | Executes optimizations 1-4 in batch mode. |
| 8 | **Show Activity Log** | View last 30 log entries. |

---

## Compatibility

| macOS Version | Code Name | Supported |
|---------------|-----------|-----------|
| 12 | Monterey | ✅ Yes |
| 13 | Ventura | ✅ Yes |
| 14 | Sonoma | ✅ Yes |
| 15 | Sequoia | ✅ Yes |

---

## Quick Start

### 1. Clone and Navigate

```bash
git clone https://github.com/instax-dutta/mac-optimiser.git
cd mac-optimiser
```

### 2. Make Executable

```bash
chmod +x mac_optimizer.sh
```

### 3. Run Normally

```bash
./mac_optimizer.sh
```

### 4. Run in Dry-Run Mode (Test First)

```bash
./mac_optimizer.sh --dry-run
```

---

## Usage Guide

### Menu Options

```
1) System Cleanup (Cache, Logs, Trash)
2) Memory Pressure Report
3) Boost Internet/Network
4) Run Maintenance Scripts
5) Flush Print Queue
6) Reindex Spotlight
7) Run ALL Safe Optimizations (1-4)
8) Show Activity Log
9) Exit
```

### Understanding the Output

- `[✔]` — Command succeeded
- `[✘]` — Command failed (see `/tmp/mac_opt_last.log` for details)
- `[DRY]` — Dry-run mode, no changes made
- `[!]` — Skipped due to version compatibility

### Log File Location

All actions are logged to:

```
~/.mac_optimizer.log
```

Open it with:

```bash
open ~/.mac_optimizer.log
```

Or view recent entries from the menu (Option 8).

---

## What Was Changed (v2.1.0 Rewrite)

### Fixed Issues

| Issue | Fix |
|-------|-----|
| Incorrect exit code checking | Replaced `print_status` with proper `run_cmd` function |
| sudo -v && chaining anti-pattern | Fixed by calling sudo -v once per function |
| set -euo pipefail + run_cmd non-zero exit | Wrapped non-critical run_cmd calls with || true |
| Glob expansion in run_cmd arguments | Replaced with safe find -delete forms |
| BATCH_MODE global state not reset | Refactored run_all to use subshell |
| Spinner function unused | Removed unused spinner() function |
| DARWIN_VERSION variable unused | Removed unused variable |

### New Features (v2.1.0)

- `--backup` flag to move files to backup instead of deleting
- `--yes` / `-y` flag for non-interactive mode
- `--version` flag to show version information
- Disk space freed summary after cleanup
- App-specific cache cleaning (Chrome, Docker, npm, etc.)
- Memory Report: top RAM-consuming processes
- Log rotation when log exceeds 500KB
- Renamed menu option 2 to "Memory Pressure Report"
- Added macOS 12 (Monterey) support
- Sysctl changes warning about temporary nature

---

## Safety Information

### What the script DOES do:

- Clears user temporary files (`~/Library/Caches`, `~/Library/Logs`, `~/.Trash`)
- Clears Xcode DerivedData
- Flushes DNS cache
- Configures network sysctls
- Runs maintenance periodic scripts
- Cancels print jobs
- Rebuilds Spotlight index

### What the script DOES NOT do:

- ❌ Delete system logs (`/private/var/log`)
- ❌ Use `sudo purge` (removed in v2.0)
- ❌ Modify personal documents
- ❌ Touch applications
- ❌ Require macOS root for most operations

### Recommendations

1. **Close applications** before running System Cleanup
2. **Use `--dry-run`** first to preview actions
3. **Review the log** after running (Option 8)

---

## Code Quality

This script passes [ShellCheck](https://www.shellcheck.net/) with:

- ⚠️ Warnings: **0**
- ⚠️ Errors: **0**
- ℹ️ Info: **0**

Enforced at top:

```bash
set -euo pipefail
```

---

## Contributing

Contributions are welcome! Please ensure:

1. ShellCheck passes with zero warnings
2. New features work on macOS 13-15
3. All changes documented

### Workflow

```bash
git fork
git checkout -b feature/YourFeature
# make changes
git commit -m "Add YourFeature"
git push origin feature/YourFeature
```

---

## License

MIT License — See [LICENSE](LICENSE) for details.

---

<div align="center">

**macOS Ultimate Optimizer** — Production-quality macOS maintenance script

[instax-dutta](https://github.com/instax-dutta) • [Issues](https://github.com/instax-dutta/mac-optimiser/issues)

</div>