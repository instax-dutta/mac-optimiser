# macOS Ultimate Optimizer

[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Version](https://img.shields.io/badge/Version-v2.1.0-blue?style=for-the-badge)](#what-was-changed-v210)
[![macOS](https://img.shields.io/badge/Supported-macOS%2012--15-333333?style=for-the-badge)](#compatibility)
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
- **Backup mode** — Move files to `/tmp` backup instead of deleting with `--backup`
- **Non-interactive mode** — Auto-confirm all prompts for cron/automation with `--yes`
- **Version gating** — Automatically skips incompatible operations per macOS version
- **Safe by design** — Never touches `/private/var/log` or uses `sudo purge`
- **ShellCheck verified** — Passes with zero warnings or errors

---

## Features

| # | Feature | Description |
|---|---------|-------------|
| 1 | **System Cleanup** | Clears user caches, logs, trash, Xcode DerivedData (shows size before deleting). |
| 2 | **App Cache Cleaning** | Cleans app-specific caches: Chrome, Chromium, Docker, npm, Yarn, pip, CocoaPods, Gradle. |
| 3 | **Memory Pressure Report** | Displays VM statistics (Free, Active, Inactive, Wired, Compressed). |
| 4 | **Top RAM Processes** | Shows top 5 memory-consuming processes by RSS. |
| 5 | **Network Booster** | Flushes DNS, configures TCP buffers, resets interface with confirmation. |
| 6 | **Maintenance Scripts** | Manually runs daily/weekly/monthly periodic scripts with spinner. |
| 7 | **Flush Print Queue** | Cancels all stuck print jobs. |
| 8 | **Reindex Spotlight** | Rebuilds Spotlight search index with spinner. |
| 9 | **Run ALL** | Executes optimizations 1-6 in batch mode. |
| 10 | **Show Activity Log** | View last 30 log entries. |
| 11 | **Disk Freed Summary** | Reports MB freed and before/after disk space after cleanup. |
| 12 | **Log Rotation** | Automatically rotates log when it exceeds 500 KB. |

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

### 5. Run with Backup Mode

```bash
./mac_optimizer.sh --backup
```

### 6. Run Non-Interactively

```bash
./mac_optimizer.sh --yes
```

### 7. Show Version

```bash
./mac_optimizer.sh --version
```

### 8. Show Help

```bash
./mac_optimizer.sh --help
```

---

## Command-Line Flags

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview all actions without making changes |
| `--backup` | Move files to `/tmp/mac_optimizer_backup_<timestamp>/` instead of deleting |
| `--yes`, `-y` | Auto-confirm all prompts (safe for cron/automation) |
| `--version` | Print `mac_optimizer v2.1.0` and exit |
| `--help` | Print usage information and exit |

Flags can be combined:

```bash
./mac_optimizer.sh --backup --yes    # Non-interactive backup mode
./mac_optimizer.sh --dry-run --yes   # Preview without prompts
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

## What Was Changed (v2.1.0)

### Bug Fixes

| Issue | Fix |
|-------|-----|
| `sudo -v && cmd` chaining only passes `sudo -v` to `run_cmd` | Call `sudo -v` once at function top; pass actual commands to `run_cmd` |
| `set -euo pipefail` + failing `run_cmd` aborts entire script | Appended `\|\| true` to all non-fatal `run_cmd` calls |
| Glob expansion (`/*`) breaks `run_cmd` argument passing | Replaced `rm -rf` glob patterns with `find -mindepth 1 -delete` |
| `BATCH_MODE` not reset on error in `run_all()` | Wrapped sub-functions in `{ } \|\| true` with explicit reset |
| Spinner function defined but never called | Wired `spinner()` into `run_maintenance` and `reindex_spotlight` |
| `DARWIN_VERSION` captured but never used | Removed unused variable |
| Duplicate `require_min_version` function definitions | Removed duplicate |

### New Features

| Feature | Details |
|---------|---------|
| `--backup` flag | Moves files to `/tmp/mac_optimizer_backup_<timestamp>/` instead of deleting |
| `--yes` / `-y` flag | Auto-confirms all prompts for non-interactive / cron use |
| `--version` flag | Prints version and exits |
| `--help` flag | Prints usage information and exits |
| Disk freed summary | Reports approximate MB freed and before/after disk space |
| App-specific cache cleaning | Chrome, Chromium, Docker, npm, Yarn, pip, CocoaPods, Gradle |
| Top 5 RAM processes | Shows PID, RSS (MB), and command for top memory consumers |
| Sysctl persistence warning | Warns that network sysctl changes are temporary (reset on reboot) |
| Log rotation | Automatically rotates `~/.mac_optimizer.log` when it exceeds 500 KB |
| Spinner on long operations | Visual feedback during maintenance scripts and Spotlight reindex |
| macOS 12 (Monterey) support | Minimum version lowered from 13 to 12 |

---

## Safety Information

### What the script DOES do:

- Clears user temporary files (`~/Library/Caches`, `~/Library/Logs`, `~/.Trash`)
- Clears Xcode DerivedData
- Clears app-specific caches (Chrome, Docker, npm, etc.)
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
3. **Use `--backup`** if you want a safety net
4. **Review the log** after running (Option 8)

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

CI enforced via GitHub Actions — see `.github/workflows/shellcheck.yml`.

---

## Contributing

Contributions are welcome! Please ensure:

1. ShellCheck passes with zero warnings
2. New features work on macOS 12-15
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

**macOS Ultimate Optimizer v2.1.0** — Production-quality macOS maintenance script

[instax-dutta](https://github.com/instax-dutta) • [Issues](https://github.com/instax-dutta/mac-optimiser/issues)

</div>