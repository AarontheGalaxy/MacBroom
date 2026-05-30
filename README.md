# MacBroom

**MacBroom** is an interactive terminal disk cleaner for macOS, written entirely in Bash. It scans 29 categories of junk in parallel, shows you exactly what it found, lets you choose precisely what to delete — and can never touch anything outside a hard-coded list of safe directories.

No Homebrew. No Python. No Ruby. No Electron. No installation required beyond cloning the repo.

```
  MacBroom
──────────────────────────────────────────────────────────────────────────────
Disk Usage: ■■■■■■■■■■■■□□□□  892.4 GB / 994.7 GB (90%)
APFS Purgeable: 12.3 GB
──────────────────────────────────────────────────────────────────────────────
▶ ● [S] User App Caches       ·····  ■■■■■■□□□□      2.1 GB   ← selected (green bold)
  ○ [S] Browser Caches        ·····  ■■■■□□□□□□      1.3 GB
  ● [M] Developer Tool Caches ·····  ■■■■■■□□□□      1.8 GB   ← selected (green)
  ○ [S] Project Artifacts     ·····                       —   ← deferred scan
  ○ [S] Node.js & JS          ·····  ■■■□□□□□□□      890 MB
  ○ [S] Python & pip          ·····  ■■□□□□□□□□      540 MB
  ○ [S] Homebrew Cache        ·····  ■■■□□□□□□□      740 MB
  ○ [M] JetBrains IDEs        ·····  ■■■■□□□□□□      1.1 GB
  ○ [M] System & App Logs     ·····  ■□□□□□□□□□      210 MB
  [S] Safe  · Application cache directories in ~/Library/Caches  (1-9/29)
──────────────────────────────────────────────────────────────────────────────
 ↑↓ Navigate  Space Toggle  → Preview  Enter Clean  A All  N None  S Status  W Whitelist  Q Quit
```

---

## Table of Contents

1. [Why MacBroom?](#why-macbroom)
2. [Quick Start](#quick-start)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [How to Launch](#how-to-launch)
6. [Understanding the Interface](#understanding-the-interface)
   - [The Scanning Screen](#the-scanning-screen)
   - [The Main Screen](#the-main-screen)
   - [The Preview Screen](#the-preview-screen)
   - [The Cleaning Screen](#the-cleaning-screen)
   - [The Done Screen](#the-done-screen)
   - [The Status Dashboard](#the-status-dashboard)
   - [The Whitelist Screen](#the-whitelist-screen)
7. [How to Clean — Step by Step](#how-to-clean--step-by-step)
   - [Quick Clean: delete an entire category](#quick-clean-delete-an-entire-category)
   - [Precise Clean: choose individual files](#precise-clean-choose-individual-files)
   - [The connection between the two modes](#the-connection-between-the-two-modes)
8. [Complete Keyboard Reference](#complete-keyboard-reference)
9. [All 29 Cleaning Modules](#all-29-cleaning-modules)
10. [Advanced Features](#advanced-features)
11. [CLI Reference](#cli-reference)
12. [Configuration](#configuration)
13. [Safety and Security](#safety-and-security)
14. [Why the Disk Bar Doesn't Change Immediately](#why-the-disk-bar-doesnt-change-immediately)
15. [Project Structure](#project-structure)
16. [Running the Tests](#running-the-tests)
17. [Module API — Adding Your Own Module](#module-api--adding-your-own-module)
18. [Troubleshooting](#troubleshooting)
19. [License](#license)

---

## Why MacBroom?

Most Mac cleaning apps are closed-source GUI applications. You click a button and files disappear — with no way to know what was actually deleted, or whether the tool is safe. MacBroom is the opposite of that.

- **Fully open source** — every line of code is readable and auditable
- **Hard-coded allowlist** — `mb_safe_rm()` refuses to delete anything outside an explicit list of safe directories; a bug in a module _cannot_ delete your home folder or system files
- **No surprises** — Preview mode shows you the exact list of files before you delete anything; nothing is deleted until you explicitly select it and confirm
- **No external runtime** — pure Bash, no Homebrew, no pip packages, no npm modules; works on any Mac out of the box
- **No network access** — zero telemetry, no update checks, no data collection of any kind
- **Audit trail** — every deletion is logged with a timestamp, full path, and size freed
- **Whitelist protection** — add any folder to the built-in whitelist and MacBroom will never touch it, even if that folder is inside a safe prefix
- **Tested** — 59 automated tests covering path safety, symlink validation, and module behavior

---

## Quick Start

```bash
git clone https://github.com/AarontheGalaxy/MacBroom.git
cd MacBroom
bash macbroom
```

That's it. MacBroom opens immediately and starts scanning. No configuration needed.

To install it system-wide so you can run `macbroom` from anywhere:

```bash
bash install.sh
```

---

## Requirements

| Requirement | Details                                                                                                 |
| ----------- | ------------------------------------------------------------------------------------------------------- |
| macOS       | 11 Big Sur or later                                                                                     |
| Bash        | 3.2+ (pre-installed on every Mac since 2007)                                                            |
| Terminal    | Any terminal with UTF-8 and 256-color support — Terminal.app, iTerm2, Ghostty, Warp, Alacritty all work |
| Disk space  | Less than 1 MB for the entire project                                                                   |

> **Recommended:** Go to `System Settings → Privacy & Security → Full Disk Access` and add your terminal app. This lets MacBroom scan protected folders like `~/Library/Mail` and `~/Library/Containers`. Without it, some modules may report smaller sizes than reality because macOS blocks access.

---

## Installation

### Option A — Install system-wide (recommended)

```bash
git clone https://github.com/AarontheGalaxy/MacBroom.git
cd MacBroom
bash install.sh
```

What the installer does:

1. Copies the entire project to `~/.macbroom/`
2. Creates a launcher script at `/usr/local/bin/macbroom` (or `~/.local/bin/macbroom` if `/usr/local/bin` is not writable)

After installation, you can type `macbroom` from any directory in any terminal session.

> **PATH note:** If the installer uses `~/.local/bin`, it will print a warning if that directory is not in your `$PATH`. Follow the printed instruction to add `export PATH="$HOME/.local/bin:$PATH"` to your `~/.zshrc` or `~/.bashrc`.

To uninstall:

```bash
bash ~/.macbroom/install.sh uninstall
```

This removes both the launcher at `/usr/local/bin/macbroom` and the project directory at `~/.macbroom/`.

### Option B — Run directly without installing

```bash
cd MacBroom
bash macbroom
```

Everything works the same. You just need to be in the project directory (or provide the full path).

---

## How to Launch

```bash
macbroom
```

MacBroom immediately starts scanning your Mac and opens the interactive interface. No arguments needed for normal use.

---

## Understanding the Interface

MacBroom has seven screens. You move between them via keyboard shortcuts.

---

### The Scanning Screen

This is the first thing you see every time MacBroom starts. It scans all 29 categories simultaneously (in parallel), so the total wait is only as long as the slowest scan — usually a few seconds.

```
  MacBroom
──────────────────────────────────────────────────────────────────────────────


              ⠙  Scanning JetBrains IDE Caches...


──────────────────────────────────────────────────────────────────────────────
Please wait while we analyze your system...
```

- The spinner `⠙` animates while scanning is in progress.
- The label shows which category is currently being measured.
- You cannot interact here — just wait a few seconds.
- When all scans finish, MacBroom automatically switches to the Main screen.

> **Note on Deferred Modules:** Project Artifacts and Large Old Files skip their scan at startup (they use `find` across large directory trees which would slow everything else down). They show `—` instead of a size. The actual scan runs the moment you open their Preview screen (`→`). When you press `←` to return, the real size appears in place of `—`.

---

### The Main Screen

This is the central control panel. It lists all 29 cleaning categories with their sizes, safety ratings, and selection state.

```
  MacBroom
──────────────────────────────────────────────────────────────────────────────
Disk Usage: ■■■■■■■■■■■■□□□□  892.4 GB / 994.7 GB (90%)
APFS Purgeable: 12.3 GB
──────────────────────────────────────────────────────────────────────────────
▶ ● [S] User App Caches       ·······  ■■■■■■□□□□      2.1 GB   ← GREEN BOLD (selected + cursor)
  ○ [S] Browser Caches        ·······  ■■■■□□□□□□      1.3 GB   ← dim
  ● [M] Developer Tool Caches ·······  ■■■■■■□□□□      1.8 GB   ← GREEN (selected)
  ○ [S] Project Artifacts     ·······                       —   ← not scanned at startup
  ○ [S] Homebrew Cache        ·······  ■■■□□□□□□□      740 MB
  ○ [M] Large Old Files       ·······                       —   ← not scanned at startup
  ○ [R] Trash                 ·······  ■■□□□□□□□□      640 MB
  [S] Safe  · Application cache directories in ~/Library/Caches  (1-7/29)
──────────────────────────────────────────────────────────────────────────────
 ↑↓ Navigate  Space Toggle  → Preview  Enter Clean  A All  N None  S Status  W Whitelist  Q Quit
```

**What each part of a row means:**

| Symbol          | Meaning                                                                      |
| --------------- | ---------------------------------------------------------------------------- |
| `▶`             | The cursor — this is the row you are currently on                            |
| `○`             | Not selected — will not be cleaned                                           |
| `●`             | Selected for cleaning                                                        |
| `[S]`           | Safe — apps rebuild these automatically, no side effects                     |
| `[M]`           | Moderate — safe to remove, but some apps may be slower on first launch after |
| `[R]`           | Risky — permanently deletes user data; must be selected manually every time  |
| `·····`         | Dot leader — visually connects the module name to its size bar               |
| `■■■□□□`        | Size bar — shows size relative to the largest category                       |
| Number on right | Total reclaimable size for this category                                     |
| `—`             | Size not yet scanned (deferred modules)                                      |

**The size number changes color** to communicate selection state at a glance:

| Size color     | Meaning                              |
| -------------- | ------------------------------------ |
| **Bold**       | Cursor is on this row (not selected) |
| **Green**      | Selected (`●`)                       |
| **Bold green** | Selected AND cursor is on this row   |
| Dim            | Not selected, not the cursor         |

**The info bar** (second row from bottom): Shows the safety badge in color (`[S]` green / `[M]` yellow / `[R]` red), followed by a one-line description of the highlighted module, and a scroll position like `(1-10/29)` when the list is taller than your terminal. You always know the safety level of the highlighted row without looking at the left column.

**The disk bar** at the top: Reads from the APFS volume and matches exactly what Finder and About This Mac report. Turns yellow above 35% usage, red above 70%.

**APFS Purgeable**: Space macOS is holding as reclaimable (Time Machine snapshots, iCloud-backed files). Separate from what MacBroom cleans. Shown only when macOS reports a non-zero value.

---

### The Preview Screen

Opened by pressing `→` on any category. Shows the exact list of files and folders inside that category, so you can choose what to delete individually.

**When you open Preview with nothing pre-selected:**

```
  MacBroom  ›  Browser Caches
──────────────────────────────────────────────────────────────────────────────
  Cache directories for Safari, Chrome, Firefox, and other browsers
✓ Safe: Browsers re-download page assets — slightly slower first load after clean
──────────────────────────────────────────────────────────────────────────────
▶ [ ] com.apple.Safari                                              1.2 GB
  [ ] com.google.Chrome                                             340 MB
  [ ] org.mozilla.firefox                                           120 MB
  [ ] com.microsoft.edgemac                                          80 MB
  [ ] com.brave.Browser                                              45 MB

──────────────────────────────────────────────────────────────────────────────
 ← Back  ↑↓ Navigate  Space to select files — nothing deleted until you select  Q Quit
```

**When you open Preview after selecting the category on the Main screen (`●`):**

```
  MacBroom  ›  Browser Caches
──────────────────────────────────────────────────────────────────────────────
  Cache directories for Safari, Chrome, Firefox, and other browsers
✓ Safe: Browsers re-download page assets — slightly slower first load after clean
──────────────────────────────────────────────────────────────────────────────
▶ [✓] com.apple.Safari                                              1.2 GB
  [✓] com.google.Chrome                                             340 MB
  [✓] org.mozilla.firefox                                           120 MB
  [✓] com.microsoft.edgemac                                          80 MB
  [✓] com.brave.Browser                                              45 MB

──────────────────────────────────────────────────────────────────────────────
 ← Back  ↑↓ Navigate  Space Toggle  / Filter  Enter Delete 5 selected  Q Quit
```

All items are pre-selected because the category was already marked `●`. You can uncheck anything you want to keep.

**What each symbol means:**

| Symbol | Meaning                                         |
| ------ | ----------------------------------------------- |
| `[ ]`  | Not selected — will NOT be deleted              |
| `[✓]`  | Selected — WILL be deleted when you press Enter |
| `▶`    | Your cursor position                            |

**The footer changes** based on selection state:

- Nothing selected → `Space to select files — nothing deleted until you select`
- Items selected → `Enter Delete N selected` (where N is the count)

**The header area** shows a description of the category and a safety note in color: green for Safe, yellow for Moderate, red for Risky — with a one-sentence explanation of what happens after deletion.

---

### The Cleaning Screen

Appears automatically while MacBroom is deleting files. You cannot interact with it — just watch the progress.

```
  MacBroom  ›  Cleaning...
──────────────────────────────────────────────────────────────────────────────
  ✓  User App Caches  (freed 2.1 GB)
  ⠙  Browser Caches  (cleaning...)
  ○  Node.js & JS Caches
──────────────────────────────────────────────────────────────────────────────
Progress: ■■■■■■■□□□□□□□□□□□□□ 1/3
```

| Symbol              | Meaning                 |
| ------------------- | ----------------------- |
| `✓` green           | Done                    |
| `⠙` cyan (animated) | Currently being cleaned |
| `○` dim             | Waiting                 |

The progress bar shows how many categories have finished out of the total selected.

---

### The Done Screen

Shown after all cleaning finishes.

```
  MacBroom  ›  Done!
──────────────────────────────────────────────────────────────────────────────
  ✓  User App Caches  (2.1 GB)
  ✓  Browser Caches  (1.3 GB)
  ✓  Node.js & JS Caches  (890 MB)

Total Freed: 4.3 GB
Note: Disk bar updates after macOS reclaims APFS purgeable space.
──────────────────────────────────────────────────────────────────────────────
Press any key to rescan and return to main menu  Q to quit
```

- **Total Freed** is the accurate total of what was deleted.
- Press **any key** (except Q) to rescan everything and return to the Main screen with updated sizes.
- Press **Q** to exit MacBroom.

> **Why doesn't the disk bar change immediately?** macOS marks deleted blocks as "purgeable" rather than freeing them instantly. The Total Freed number is correct; the disk bar takes a little time to catch up. See [Why the Disk Bar Doesn't Change Immediately](#why-the-disk-bar-doesnt-change-immediately) for the full explanation.

---

### The Status Dashboard

Opened by pressing `S` on the Main screen. Shows a real-time snapshot of your Mac's CPU, RAM, swap, load averages, uptime, and the top memory-consuming processes.

```
  MacBroom  ›  System Status
──────────────────────────────────────────────────────────────────────────────

  CPU    ■■■□□□□□□□□□□□□□  24.3% user  8.1% sys  67.6% idle
  RAM    ■■■■■■■□□□□□□□□□  11.2 GB used  3.4 GB cached  1.8 GB free  / 16.0 GB
  Swap   ■■□□□□□□□□□□□□□□  512 MB / 2.0 GB
  Load   1.42  0.98  0.84  (1m / 5m / 15m)
  Uptime 3 days, 14:22

──────────────────────────────────────────────────────────────────────────────
  Top Processes by CPU:
   24.1%  Xcode                  PID 1234
   18.3%  Google Chrome          PID 5678
    9.7%  WindowServer           PID 91
    4.2%  Slack                  PID 2345
    2.1%  Docker Desktop         PID 6789
──────────────────────────────────────────────────────────────────────────────
  R Refresh  ← / Q Back
```

**What each metric means:**

| Metric        | Source                | Details                                                                |
| ------------- | --------------------- | ---------------------------------------------------------------------- |
| CPU           | `top -l 1`            | User, sys, and idle percentages from the current sample                |
| RAM           | `vm_stat`             | Active + wired = used; inactive = cached; free page count × 4096 bytes |
| Swap          | `sysctl vm.swapusage` | Virtual memory swapped to disk (only shown if swap is in use)          |
| Load          | `uptime`              | 1-minute, 5-minute, and 15-minute load averages                        |
| Uptime        | `uptime`              | Time since last boot                                                   |
| Top processes | `ps aux`              | Top 5 processes sorted by CPU usage                                    |

**How to use it:**

- Press `R` to refresh all metrics with a new sample
- Press `←` or `Q` to return to the Main screen

This screen helps you decide which cleaning actions will have the most impact. For example, if RAM is nearly full, running Memory Purge (`memory_purge` module) will immediately free inactive pages. If swap is heavily used, reducing RAM pressure will help disk performance.

---

### The Whitelist Screen

Opened by pressing `W` on the Main screen. Lets you permanently protect any folder from being deleted by MacBroom — even if that folder is inside a normally-cleanable location.

```
  MacBroom  ›  Whitelist
──────────────────────────────────────────────────────────────────────────────
  Paths listed here are PROTECTED — MacBroom will never delete them.
──────────────────────────────────────────────────────────────────────────────
▶ /Users/eren/Downloads/important-project
  /Users/eren/Library/Caches/my-app

──────────────────────────────────────────────────────────────────────────────
  ↑↓ Navigate  A Add  D Delete  Enter Confirm  ← / Q Back
```

**When adding a path:**

```
  Add path: /Users/eren/Documents/client-work_
```

**How the whitelist works:**

- Whitelist entries are stored in `~/.config/macbroom/whitelist`, one path per line
- You can use `~` as a shorthand for your home directory in the file
- `mb_safe_rm()` checks the whitelist before every deletion — if the target is inside a whitelisted path, the deletion is skipped and a warning is printed
- The whitelist is loaded at startup and reloaded after every add/remove operation

**Navigation:**

| Key         | Action                                                  |
| ----------- | ------------------------------------------------------- |
| `↑` / `↓`   | Move cursor between entries                             |
| `A`         | Enter add mode — type a path and press Enter to confirm |
| `D`         | Delete the highlighted entry from the whitelist         |
| `Enter`     | Confirm typed path (in add mode)                        |
| `Backspace` | Delete last character (in add mode)                     |
| `←` or `Q`  | Return to Main screen                                   |

**Use case example:** You have `~/Downloads/client-assets/` which you never want accidentally cleaned, even though `~/Downloads` is in the safe-path list. Adding it to the whitelist guarantees MacBroom will skip it entirely, regardless of what any module reports.

---

## How to Clean — Step by Step

MacBroom has two ways to clean. Understanding both is important.

---

### Quick Clean: delete an entire category

Use this when you're confident about a category and want to remove everything in it.

**Step 1** — Launch MacBroom. Wait for the scan to finish.

**Step 2** — Use `↑` / `↓` to move the `▶` cursor to the category you want to clean.

**Step 3** — Press `Space`. The `○` changes to `●`, meaning this category is selected.

```
  ▶ ● [S] User App Caches  ·······  ■■■■■■□□□□    2.1 GB   ← green bold
```

**Step 4** — Repeat for any other categories you want to clean.

**Step 5** — Press `Enter`. MacBroom cleans every selected category and shows the Done screen.

**Shortcut:** Press `A` to select all Safe `[S]` and Moderate `[M]` categories at once (Risky `[R]` are always excluded from `A`). Press `N` to deselect everything.

```
Example: clean User App Caches and Browser Caches

  ↓  (navigate to User App Caches)
  Space  →  ●
  ↓  (navigate to Browser Caches)
  Space  →  ●
  Enter  →  both are cleaned
```

---

### Precise Clean: choose individual files

Use this when you want to see exactly what's inside a category before deleting, or when you only want to delete some items and keep others.

**Step 1** — Launch MacBroom. Wait for the scan to finish.

**Step 2** — Navigate to the category you want to inspect.

**Step 3** — Press `→` (right arrow). The Preview screen opens and lists every file and folder inside, sorted largest first.

**Step 4** — Browse with `↑` / `↓`. Each row shows a file or folder name and its size.

**Step 5** — Press `Space` on any item to check or uncheck it.

```
  [ ] com.apple.Safari           1.2 GB   ← not selected, will NOT be deleted
  [✓] com.google.Chrome          340 MB   ← selected, WILL be deleted
  [ ] org.mozilla.firefox        120 MB   ← not selected, will NOT be deleted
```

> **Nothing is deleted until you explicitly check something and press `Enter`.** The footer shows exactly how many items are selected: `Enter Delete 1 selected`. If the footer says `Space to select files — nothing deleted until you select`, that means zero items are checked and pressing Enter does nothing.

**Step 6** — When you've selected everything you want to delete, press `Enter`. Only the checked items are deleted.

**Step 7** — Press `←` (left arrow) at any time to go back without deleting anything.

```
Example: delete only Chrome's cache, keep Safari and Firefox

  → (open Browser Caches preview)
  ↓  (navigate to com.google.Chrome)
  Space  →  [✓]
  Enter  →  only Chrome cache deleted
```

---

### The connection between the two modes

The two modes are linked — selecting a category on the Main screen automatically pre-selects all of its contents in Preview.

**Scenario A — Select on Main screen, then clean directly:**

```
Space (on Browser Caches)  →  ●
Enter  →  everything in Browser Caches is deleted
```

**Scenario B — Select on Main screen, then open Preview to review:**

```
Space (on Browser Caches)  →  ●
→ (open Preview)  →  all items are already [✓]
Space (on com.apple.Safari)  →  unchecks Safari
Enter  →  everything except Safari is deleted
```

**Scenario C — Open Preview without selecting first:**

```
→ (open Preview, module is still ○)  →  all items start as [ ]
Space on what you want  →  [✓]
Enter  →  only your selections are deleted
```

This gives you full flexibility:

- `A` then `Enter` = delete everything in all Safe/Moderate categories at once
- `A` then `→` on a category = review and remove individual items before committing
- `→` without selecting = browse freely and pick exactly what you want

---

## Complete Keyboard Reference

### Main Screen

| Key        | Action                                                                               |
| ---------- | ------------------------------------------------------------------------------------ |
| `↑` or `k` | Move cursor up one row                                                               |
| `↓` or `j` | Move cursor down one row                                                             |
| `Space`    | Toggle the highlighted category on (`●`) or off (`○`)                                |
| `→` or `l` | Open the Preview screen for the highlighted category                                 |
| `Enter`    | Start cleaning all selected (`●`) categories                                         |
| `A`        | Select all Safe `[S]` and Moderate `[M]` categories (Risky `[R]` are always skipped) |
| `N`        | Deselect all categories                                                              |
| `D`        | Toggle Dry-Run mode on/off (no files are deleted in dry-run)                         |
| `S`        | Open the System Status dashboard                                                     |
| `W`        | Open the Whitelist screen                                                            |
| `Q`        | Quit MacBroom                                                                        |

### Preview Screen

| Key         | Action                                                                                                          |
| ----------- | --------------------------------------------------------------------------------------------------------------- |
| `↑` or `k`  | Move cursor up one row                                                                                          |
| `↓` or `j`  | Move cursor down one row                                                                                        |
| `Space`     | Check `[✓]` or uncheck `[ ]` the highlighted item                                                               |
| `A`         | Check all currently visible items (respects active filter)                                                      |
| `N`         | Uncheck all currently visible items (respects active filter)                                                    |
| `Enter`     | **If cursor is on an unchecked folder:** drill into it. **If any items are checked:** delete all checked items. |
| `←` or `h`  | Go back one level (if inside a subfolder) or return to Main screen                                              |
| `Esc`       | If a filter is active: clear the filter. Otherwise: return to Main screen.                                      |
| `/`         | Enter filter mode — type to search items by name (case-insensitive, real-time)                                  |
| `Backspace` | Delete the last character of the search filter                                                                  |
| `Q`         | Quit MacBroom                                                                                                   |

### Status Screen

| Key        | Action                                           |
| ---------- | ------------------------------------------------ |
| `R`        | Refresh — re-collect all CPU/RAM/process metrics |
| `←` or `Q` | Return to Main screen                            |

### Whitelist Screen

| Key         | Action                                                  |
| ----------- | ------------------------------------------------------- |
| `↑` / `↓`   | Move cursor between entries                             |
| `A`         | Enter add mode — type a path and press Enter to confirm |
| `D`         | Delete the highlighted entry                            |
| `Enter`     | Confirm typed path (in add mode)                        |
| `Backspace` | Delete last character (in add mode)                     |
| `←` or `Q`  | Return to Main screen                                   |

### Done Screen

| Key                | Action                                                             |
| ------------------ | ------------------------------------------------------------------ |
| Any key (except Q) | Rescan all categories and return to Main screen with updated sizes |
| `Q`                | Quit MacBroom                                                      |

### Dry-Run Mode

Press `D` on the Main screen to activate Dry-Run mode. The title bar changes to `MacBroom (DRY RUN)`. In this mode:

- Scanning and all file listings are real — you see actual sizes and actual file names
- The Preview screen works normally
- Pressing `Enter` to clean **does not delete anything**
- The Done screen shows how much _would have been_ freed
- Press `D` again to turn Dry-Run mode off

Dry-Run is the safest way to understand exactly what MacBroom would do before committing to a real clean.

---

## All 29 Cleaning Modules

### Safety Ratings

Every category has a badge that tells you how safe it is to clean. These badges are shown in the info bar as you navigate.

| Badge            | Name         | What it means                                                                                                                                                 |
| ---------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `[S]` **green**  | **Safe**     | Pure caches that apps rebuild automatically. No data loss, no side effects.                                                                                   |
| `[M]` **yellow** | **Moderate** | Safe to remove, but some apps may be slightly slower on first launch while they rebuild indexes or re-download dependencies.                                  |
| `[R]` **red**    | **Risky**    | Permanently deletes user data — attachments, backups, AI models. May not be recoverable. **Excluded from the `A` key. Must be selected manually every time.** |

---

### 1. User App Caches — `user_caches` `[S]`

**What it cleans:** Every application cache folder inside `~/Library/Caches`. This is usually the single largest source of reclaimable space on any Mac. Every app stores temporary data here — downloaded thumbnails, compiled resource files, search indexes, rendered previews. All of it is regenerated automatically when the app needs it again.

**After cleaning:** Apps recreate their caches on next use. A brief slowdown the first time you open each app is possible, but nothing is permanently lost.

---

### 2. Browser Caches — `browser` `[S]`

**What it cleans:** Cache folders for:

- Safari (`com.apple.Safari`)
- Google Chrome (`com.google.Chrome`)
- Arc Browser (`company.thebrowser.Browser`)
- Mozilla Firefox (`org.mozilla.firefox`)
- Microsoft Edge (`com.microsoft.edgemac`)
- Brave Browser (`com.brave.Browser`)
- Vivaldi (`Vivaldi`)
- Opera (`com.operasoftware.Opera`)

**After cleaning:** Web pages load slightly slower on the first visit after cleaning while the browser re-downloads page assets (images, CSS, JavaScript). After that, browsing returns to normal speed.

---

### 3. Developer Tool Caches — `dev_tools` `[M]`

**What it cleans:**

- Xcode DerivedData (`~/Library/Developer/Xcode/DerivedData`) — compiled build artifacts and intermediate files generated during iOS/macOS development
- iOS Simulator caches (`~/Library/Developer/CoreSimulator/Caches`) — device runtime images cached by the Simulator

**After cleaning:** Xcode recompiles your project from scratch on the next build (takes longer than usual). The Simulator re-downloads device images as needed. Your source code and project files are never touched.

---

### 4. Project Artifacts — `project_artifacts` `[S]` _(deferred)_

**What it cleans:** Build artifact directories that development tools regenerate automatically, found across your developer project folders. Searches up to 8 directory levels deep inside:

- `~/Desktop`, `~/Documents`, `~/Developer`, `~/Projects`, `~/src`, `~/code`, `~/repos`, `~/workspace`

**Artifact directory names targeted:**

| Name            | Tool                  |
| --------------- | --------------------- |
| `node_modules`  | npm, yarn, pnpm, bun  |
| `__pycache__`   | Python                |
| `.next`         | Next.js               |
| `.nuxt`         | Nuxt.js               |
| `.pytest_cache` | pytest                |
| `.mypy_cache`   | mypy                  |
| `.ruff_cache`   | ruff                  |
| `.turbo`        | Turborepo             |
| `.parcel-cache` | Parcel                |
| `.svelte-kit`   | SvelteKit             |
| `.build`        | Swift Package Manager |
| `.dart_tool`    | Dart / Flutter        |
| `.tox`          | tox                   |
| `.angular`      | Angular CLI           |
| `.vite`         | Vite                  |
| `.expo`         | Expo                  |
| `.docusaurus`   | Docusaurus            |
| `.cache`        | Various build tools   |

> **Why it shows `—` on the Main screen:** This module uses `find` with a depth of 8 across multiple large directories — potentially scanning thousands of subdirectories. Running it at startup alongside 28 other scans would make the initial scan slow. The actual scan runs the moment you open the Preview screen (`→`). When you press `←` to return, the real size replaces `—`.

**After cleaning:** Build tools regenerate these directories on the next build. Your source code, lock files, and configuration are never touched.

---

### 5. System & App Logs — `system_logs` `[M]`

**What it cleans:** Log files and crash reports older than `MB_LOG_AGE_DAYS` days (default: 7). Recent logs are always preserved. MacBroom's own log directory is never touched.

User logs:
- `~/Library/Logs` — per-user application logs and crash reports

System logs (requires `sudo -n` access):
- `/Library/Logs`, `/private/var/log`, `/private/var/db/diagnostics`, `/private/var/db/DiagnosticPipeline`, `/private/var/db/powerlog`

**After cleaning:** Old logs are gone. Apps continue writing new logs normally. No impact on running applications.

---

### 6. Temp Files — `temp_files` `[S]`

**What it cleans:** Temporary files in `/private/tmp` and `/private/var/tmp` that are older than `MB_TEMP_AGE_DAYS` days (default: 3). These are files apps create for short-lived purposes and typically never clean up themselves.

**After cleaning:** No impact. macOS and apps create new temp files as needed.

---

### 7. Node.js & JS Caches — `node_cache` `[S]`

**What it cleans:**

- npm global cache (`~/.npm`)
- Yarn cache (`~/.yarn`)
- pnpm content-addressable store (`~/.pnpm-store`)
- Bun package cache (`~/.bun`)
- node-gyp build cache

**After cleaning:** Package managers re-download packages from the registry on the next `npm install` / `yarn install` / etc. Your project `node_modules` folders and lock files are not touched — only the global download cache is removed.

---

### 8. Python & pip Caches — `python_cache` `[S]`

**What it cleans:**

- pip download cache (`~/.cache/pip`)
- conda package cache (`~/.conda/pkgs`)
- Poetry cache (`~/.poetry/cache` or `~/.cache/pypoetry`)
- pyenv build artifacts (`~/.pyenv/cache`)

**After cleaning:** pip, conda, and poetry re-download packages from their registries on next install. Your virtual environments and installed packages are not affected.

---

### 9. JetBrains IDE Caches — `jetbrains_cache` `[M]`

**What it cleans:** Cache and log directories for all JetBrains products found in `~/Library/Caches` and `~/Library/Logs`:

- IntelliJ IDEA, PyCharm, WebStorm, GoLand, CLion, DataGrip, Rider
- Android Studio (JetBrains distribution)
- PhpStorm, RubyMine, AppCode, and any other JetBrains IDE

**After cleaning:** The IDE rebuilds its internal indexes and caches the next time it opens. For large projects, IntelliJ-based IDEs can take several minutes to re-index. Your project files and IDE settings are never touched.

---

### 10. VS Code Caches — `vscode_cache` `[S]`

**What it cleans:** Cache directories for:

- Visual Studio Code: `Cache`, `CachedData`, `CachedExtensions`, `GPUCache`, `logs`
- Cursor: `Cache`, `CachedData`
- Windsurf: `Cache`

All under `~/Library/Application Support/<editor>/`.

**After cleaning:** Each editor regenerates its caches on next launch. Your extensions, settings, and workspace state are not affected.

---

### 11. Flutter & Dart Caches — `flutter_cache` `[S]`

**What it cleans:**

- Flutter pub package cache (`~/.pub-cache`)
- Dart tool cache (`~/.dart`)
- Flutter tools stamp cache (`~/Library/Caches/flutter_tools`)

**After cleaning:** `flutter pub get` or `dart pub get` re-downloads packages from pub.dev on the next build. Your project's `pubspec.lock` and `lib/` source files are not touched.

---

### 12. Go Module Cache — `go_cache` `[S]`

**What it cleans:**

- Go module download cache (`~/go/pkg/mod/cache`)
- Go build cache (`~/Library/Caches/go-build`)

**After cleaning:** `go build` re-downloads modules from the Go module proxy and recompiles from source on the next build. Your `go.mod`, `go.sum`, and source files are untouched.

---

### 13. Rust & Cargo Cache — `rust_cache` `[S]`

**What it cleans:**

- Cargo registry index and downloaded crate sources (`~/.cargo/registry`)
- Cargo git source cache (`~/.cargo/git`)

**After cleaning:** Cargo re-downloads crates from crates.io on the next `cargo build`. Your project's `target/` directory and `Cargo.lock` are not touched.

---

### 14. Ruby & CocoaPods Cache — `ruby_cache` `[S]`

**What it cleans:**

- RubyGems download cache (`~/.gem/cache`)
- CocoaPods download cache (`~/Library/Caches/CocoaPods`)

**After cleaning:** Bundler re-downloads gems on next `bundle install`. CocoaPods re-downloads pod sources on next `pod install`. Your installed gems and pods are not affected.

---

### 15. Homebrew Cache — `brew_cache` `[S]`

**What it cleans:**

- Homebrew download cache — all `.tar.gz`, `.bottle`, and other downloaded archives (location determined dynamically via `brew --cache`, typically `~/Library/Caches/Homebrew`)
- Old installed formula and cask versions via `brew cleanup --prune=all`
- Unused leaf dependencies via `brew autoremove`

**Requires:** Homebrew must be installed (`brew` must be in `$PATH`). If Homebrew is not installed, this module is automatically skipped.

**Cache location detection:** MacBroom calls `brew --cache` to find the actual cache directory. If that command fails, it falls back to `~/Library/Caches/Homebrew`. This handles non-standard Homebrew installations (e.g., custom `HOMEBREW_PREFIX`).

**After cleaning:** Homebrew re-downloads formulae and casks from GitHub when you run `brew install` or `brew upgrade`. `brew autoremove` may uninstall packages that were installed as dependencies of something you later removed — if that's unexpected, run `brew list` first to review.

---

### 16. Java & Gradle Cache — `java_cache` `[S]`

**What it cleans:**

- Gradle module cache (`~/.gradle/caches`)
- Gradle daemon files (`~/.gradle/daemon`)
- Gradle build cache (`~/Library/Caches/gradle`)

**After cleaning:** Gradle re-downloads JARs and dependencies from Maven Central on the next build. The first build after cleaning may be significantly slower. Your project source files and `build.gradle` are not touched.

---

### 17. Docker Build Cache — `docker_cache` `[M]`

**What it cleans:**

- Docker BuildKit cache layers (equivalent to `docker builder prune`)
- Dangling (untagged) images not referenced by any container

**Requires:** Docker Desktop must be installed and running.

**After cleaning:** The next `docker build` rebuilds all image layers from scratch. Running containers and named/tagged images are never affected.

---

### 18. Android SDK Cache — `android_cache` `[S]`

**What it cleans:**

- Android SDK temporary files and download cache (`~/Library/Android`)
- Android emulator cache (`~/.android/cache`)

**After cleaning:** Android Studio regenerates SDK indexes on the next project sync. Your SDK components, AVD (emulator) configurations, and project files are not affected.

---

### 19. iMessage Attachments — `imessage_attachments` `[R]`

**What it cleans:**

- `~/Library/Messages/Attachments` — photos, videos, audio files, and documents received in the Messages app
- `~/Library/Messages/StickerCache` — downloaded sticker packs

**After cleaning:** Files are removed from local storage. In most cases they remain visible in the conversation as thumbnails and can be re-downloaded from iCloud if iMessage sync is enabled. If iCloud Messages is disabled, files may be permanently unrecoverable.

> **This is a Risky `[R]` module.** Always open Preview (`→`) to review attachments and their sizes before deleting.

---

### 20. Maintenance Tasks — `maintenance` `[M]`

**What it does** (runs as a batch — no individual files to preview):

1. **TouchID for sudo** — Attempts to enable TouchID authentication for `sudo` in the current session (macOS 13 Ventura and later). Writes the `pam_tid.so` entry to `/etc/pam.d/sudo_local`. If already enabled, this step is silently skipped. This makes all subsequent `sudo` calls in the maintenance task (and the rest of the session) usable with your fingerprint instead of typing your password.
2. **DNS cache flush** — `dscacheutil -flushcache` and `killall -HUP mDNSResponder`. Clears stale DNS entries that can cause websites to not resolve correctly.
3. **Font cache rebuild** — `atsutil databases -remove`. Forces macOS to rebuild the font database, fixing font rendering issues. Takes effect after logout.
4. **APFS local snapshot purge** — Deletes local Time Machine snapshots via `tmutil deletelocalsnapshots`. Before running, Dry-Run mode shows exactly how many snapshots exist. During the actual clean, MacBroom prints the snapshot count and a "cannot be undone" warning before proceeding.
5. **Launch Services reset** — Re-registers all apps with `lsregister -kill -r -domain local -domain system -domain user`, fixing broken "Open With" menus and stale file associations.

**About TouchID for sudo:**

macOS 13+ supports PAM (Pluggable Authentication Module) based TouchID via `/etc/pam.d/sudo_local`. MacBroom prepends the following line to that file if it is missing:

```
auth       sufficient     pam_tid.so
```

If `/etc/pam.d/sudo_local` does not exist, MacBroom creates it. On macOS 12 or earlier, this step is silently skipped. If you later want to undo this manually:

```bash
sudo rm /etc/pam.d/sudo_local   # if MacBroom created it
# or remove the pam_tid line with a text editor if the file had prior content
```

**Note:** Because this module runs system commands rather than deleting individual files, the Preview screen shows nothing to select. Selecting it and pressing `Enter` runs all tasks automatically.

> **About snapshot deletion:** Local Time Machine snapshots enable features like "Revert to" in Finder and serve as an emergency restore source. Deleting them is safe if you have a full network backup, but consider whether you rely on local snapshots before running this task.

---

### 21. Memory Purge — `memory_purge` `[M]`

**What it does:** Calls `sudo purge` to flush inactive memory pages and return them to the free pool.

**Important:** This module frees RAM, not disk space. It will always report 0 bytes freed on the Done screen.

**After running:** Apps that had data sitting in inactive memory may need to reload it, causing a brief slowdown on first use.

> **Tip:** Open the Status dashboard (`S`) before and after running Memory Purge to see the RAM bar drop in real time.

---

### 22. App Leftovers — `app_leftovers` `[M]`

**What it cleans:** Support files, preference files, and caches left behind by applications that have been uninstalled. Searches inside:

- `~/Library/Application Support`
- `~/Library/Caches`
- `~/Library/Preferences`
- `~/Library/Logs`
- `~/Library/Containers`
- `~/Library/Group Containers`
- `~/Library/Saved Application State`
- `~/Library/HTTPStorages`

**Targeted search:** Set the `MB_APP_LEFTOVERS_QUERY` environment variable to search for a specific app's leftovers:

```bash
MB_APP_LEFTOVERS_QUERY="Spotify" macbroom list app_leftovers
MB_APP_LEFTOVERS_QUERY="Spotify" macbroom clean app_leftovers
```

The search is case-insensitive and matches partial names. Minimum 3 characters.

**After cleaning:** No impact — these are files from apps that are no longer installed.

---

### 23. Orphaned App Files — `orphaned_files` `[M]`

**What it cleans:** Two types of orphaned data:

**1. Orphaned bundle support directories**

Directories in standard app data locations whose names match a bundle ID pattern (e.g., `com.company.AppName`) but have **no corresponding application installed** in `/Applications` or `~/Applications`.

MacBroom queries Spotlight's `mdfind` to get the full list of installed bundle IDs and compares them against directory names. Anything not matching a known installed app is flagged as an orphan.

Searches:

- `~/Library/Application Support`
- `~/Library/Containers`
- `~/Library/Group Containers`
- `~/Library/Saved Application State`
- `~/Library/Caches` (bundle-style names only: `com.*`, `org.*`, `io.*`, `net.*`, `co.*`, `app.*`)

Returns up to 50 results sorted by size, largest first.

**2. Orphaned dotfile directories**

Hidden directories in your home folder (`~/.<name>`) whose associated command-line tool is no longer installed in `$PATH` and whose name does not match any known tool in MacBroom's exclusion list.

MacBroom scans `~` for directories matching `.*`, then checks:

- Is the directory in `MB_PROTECTED_PATHS`? → skip (always safe)
- Does a binary named `<name>` exist in `$PATH`? → skip (tool is installed)
- Is the name in the known-tools list? → skip (tool is known even if binary is missing)

Known tools that are excluded regardless of binary presence:

```
npm yarn pnpm bun cargo gem gradle maven conda poetry pyenv
flutter dart go rust ruby java python python3 node
ollama lmstudio huggingface
brew git svn hg
docker kubectl helm terraform ansible
gcloud aws azure
code cursor windsurf idea pycharm webstorm goland
vim nvim emacs nano
tmux screen zellij
iterm2 alacritty warp ghostty
rbenv volta nvm asdf sdkman tfenv gvm
oh-my-zsh antigen antibody zplug zgen zinit
fzf ripgrep fd bat eza lsd
jenv jabba conan
```

Dotfile orphans are labeled `[dotfile] <name>` in the Preview screen so you can distinguish them from bundle orphans.

**System bundle exclusions:** macOS creates many directories for background daemons and system services. MacBroom automatically skips these:

| Excluded prefix                                   | Why                                          |
| ------------------------------------------------- | -------------------------------------------- |
| `com.apple.*`                                     | macOS system daemons and background services |
| `com.google.Keystone*`                            | Google's auto-update framework               |
| `com.microsoft.autoupdate*`                       | Microsoft's auto-update framework            |
| `com.adobe.acc*`, `com.adobe.AdobeCreativeCloud*` | Adobe's background services                  |
| `com.crashlytics.*`                               | Firebase/Crashlytics crash reporting         |
| `io.fabric.*`                                     | Fabric SDK (now Firebase)                    |
| `com.bugsnag.*`                                   | Bugsnag error reporting                      |
| `com.sentry.*`                                    | Sentry error reporting                       |

> **Always use Preview (`→`) before cleaning this module.** Despite the exclusions, some third-party apps use a bundle ID that differs from their visible `.app` name. Review the list before deleting.

---

### 24. Installer Files — `installer_files` `[S]`

**What it cleans:** Disk image and installer files in `~/Downloads` that are older than `MB_INSTALLER_AGE_DAYS` days (default: 14). These accumulate silently after app installation — the app is already installed, and the installer file is no longer needed.

**File types targeted:**

- `.dmg` — macOS disk images (most common installer format)
- `.pkg` — macOS package installers
- `.iso` — optical disk images

**Search scope:** `~/Downloads` up to 3 directory levels deep.

**Configuration:**

```bash
export MB_INSTALLER_AGE_DAYS=30   # only clean installers older than 30 days (default: 14)
```

**After cleaning:** Installer files are permanently deleted. If you need to re-install an app, download a fresh copy from the vendor's website.

> **Tip:** Open Preview (`→`) to review the exact file names and sizes before cleaning. You may find installers for apps you actually want to keep (e.g., a downloaded OS upgrade or a large development tool).

---

### 25. Large Old Files — `large_old_files` `[M]` _(deferred)_

**What it cleans:** Files larger than `MB_LOF_MIN_SIZE_MB` MB (default: 500 MB) that have not been accessed in more than 180 days. Searches up to 6 levels deep inside:

- `~/Downloads`
- `~/Documents`
- `~/Desktop`
- `~/Music`
- `~/Movies`
- `~/Pictures`

**Why it shows `—` on the Main screen:** This module uses `find` across multiple large directories, which takes too long to run at startup alongside 28 other scans. The actual scan runs the moment you open the Preview screen (`→`). When you press `←` to return, the real size replaces `—` and the module participates correctly in the size ranking.

**After cleaning:** Files are permanently deleted. This module targets personal files (videos, disk images, archives), not system caches.

> **Always use Preview (`→`) before cleaning this module.** These are your personal files. Carefully review every item before deleting.

---

### 26. iOS Backups — `ios_backups` `[R]`

**What it cleans:** iPhone and iPad backup folders created by Finder (macOS Catalina+) or iTunes:

- `~/Library/Application Support/MobileSync/Backup`

**After cleaning:** The backup is permanently deleted. MacBroom cannot recover it. Always make a fresh backup via Finder before running this module.

> **This is a Risky `[R]` module.** Open Preview to see each backup's name, date, and size before deciding.

---

### 27. Mail Attachments — `mail_attachments` `[M]`

**What it cleans:** Locally cached email attachments older than `MB_MAIL_AGE_DAYS` days (default: 90). Searches:

- `~/Library/Mail` — main Mail data directory
- `~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads`

Mail.app must be closed before cleaning. If Mail is running, this module is skipped automatically.

**After cleaning:** The Mail app re-downloads attachments from the server the next time you open the relevant email. If the original email has been deleted from the server, the attachment may be unrecoverable.

---

### 28. AI Model Cache — `ai_models` `[R]`

**What it cleans:**

- Ollama model files (`~/.ollama/models`)
- LM Studio models (`~/Library/Application Support/LM Studio/models`)
- HuggingFace model cache (`~/.cache/huggingface`)
- PyTorch model cache (`~/.cache/torch`)

**After cleaning:** Model files are permanently deleted. They can be re-downloaded, but individual models range from hundreds of MB to tens of GB.

> **This is a Risky `[R]` module.** Open Preview to see each model's name and size individually before deciding.

---

### 29. Trash — `trash` `[R]`

**What it cleans:**

- `~/.Trash` — your main Trash folder
- `.Trashes` folders on any mounted external drives (`/Volumes/*/.Trashes`)

**After cleaning:** All Trash contents are permanently deleted. This is equivalent to macOS's "Empty Trash." The deletion log records this operation but files cannot be restored.

> **This is a Risky `[R]` module.** Open Preview to review Trash contents before emptying.

---

## Advanced Features

### Drill-Down: explore inside a folder

In the Preview screen, if a row is a directory and it is **not checked** (`[ ]`), pressing `Enter` enters that directory and shows its contents one level deeper — sorted by size, just like the parent level.

A breadcrumb line appears at the top showing where you are:

```
Path: /com.google.Chrome/Default/Cache/
```

You can navigate and select files at this deeper level exactly as you would at the top level. Press `←` or `h` to go back up one level.

**The rule for Enter in Preview:**

- Cursor on an **unchecked directory** → drill into it
- **Any items are checked** → delete everything that is checked (regardless of cursor position)

---

### Filter: search by name inside Preview

Press `/` in the Preview screen to enter filter mode. A search bar appears:

```
/ filter: chrome_
```

Type any part of a file or folder name. The list narrows in real time (case-insensitive). Scroll position and cursor reset to the top of the filtered list.

- `Backspace` — delete the last character of the filter
- `Esc` — clear the filter and exit filter mode
- While a filter is active, `A` and `N` only affect currently visible (filtered) items

---

### Deletion Log and Session History

MacBroom logs every file it deletes. Logs are stored at:

```
~/Library/Logs/MacBroom/operations.log   — every deletion with timestamp and size
~/Library/Logs/MacBroom/errors.log       — paths that failed and why
```

A session starts when you press `Enter` to begin cleaning and ends when all categories finish.

```bash
macbroom --log list        # List all recorded sessions with timestamps
macbroom --log last        # Show what was deleted in the most recent session
```

> **Important:** MacBroom permanently deletes files. The deletion log is an audit trail only — files cannot be restored from it. Move anything you may need to your Desktop before cleaning.

---

### JSON Output

The `--json` flag produces machine-readable output for scripts and native app integrations:

```bash
macbroom scan --json         # Disk stats and sizes for all 29 categories
macbroom list browser --json # Individual items inside a specific category
```

Example scan output:

```json
{
  "disk": { "used_kb": 921600000, "total_kb": 994050048, "free_kb": 72450048 },
  "modules": [
    { "id": "user_caches", "label": "User App Caches", "size_kb": 2150400 },
    { "id": "browser", "label": "Browser Caches", "size_kb": 1331200 },
    { "id": "brew_cache", "label": "Homebrew Cache", "size_kb": 757760 }
  ]
}
```

---

### Scheduled Cleaning with launchd

MacBroom can install a launchd job that runs automatically on a schedule:

```bash
macbroom --install-cron                   # Every 7 days, Safe categories only (default)
macbroom --install-cron 3 moderate        # Every 3 days, Safe and Moderate categories
macbroom --install-cron 1 safe            # Every day, Safe categories only
macbroom --cron-status                    # Show the current schedule
macbroom --remove-cron                    # Remove the scheduled job
```

The plist is installed at `~/Library/LaunchAgents/com.macbroom.cron.plist`. Scheduled runs use headless mode (no TUI, no prompts). Risky `[R]` categories are excluded from all scheduled runs — they require the explicit `--risky` flag on a manual headless call to be included.

---

### Headless Mode

Runs a full clean silently with no TUI. Designed for scripts and manual cron entries:

```bash
macbroom --headless --safe        # Clean all [S] Safe categories
macbroom --headless --moderate    # Clean all [S] and [M] categories
```

Prints a single summary line on completion:

```
  ✓ Headless clean complete — 4.2 GB freed
```

---

## CLI Reference

| Command                                  | Description                                     |
| ---------------------------------------- | ----------------------------------------------- |
| `macbroom`                               | Open the interactive TUI                        |
| `macbroom --dry-run`                     | Open the TUI in Dry-Run mode                    |
| `macbroom --version`                     | Print version string                            |
| `macbroom --help`                        | Print usage reference                           |
| `macbroom scan`                          | Print a disk usage report for all 29 categories |
| `macbroom scan --json`                   | Same, as JSON                                   |
| `macbroom list <module>`                 | List individual items inside a category         |
| `macbroom list <module> --json`          | Same, as JSON                                   |
| `macbroom clean <module> [<module>...]`  | Clean one or more specific categories           |
| `macbroom clean --all`                   | Clean all categories (including Risky)          |
| `macbroom clean --all --dry-run`         | Preview what `--all` would delete               |
| `macbroom --log list`                    | List all recorded deletion log sessions         |
| `macbroom --log last`                    | Show what was deleted in the last session       |
| `macbroom --install-cron [days] [level]` | Schedule automatic cleaning                     |
| `macbroom --remove-cron`                 | Remove the scheduled job                        |
| `macbroom --cron-status`                 | Show current schedule                           |
| `macbroom --headless --safe`             | Silent clean, Safe categories only              |
| `macbroom --headless --moderate`         | Silent clean, Safe + Moderate categories        |

**Valid module IDs for `list` and `clean`:**

```
user_caches          browser              dev_tools            project_artifacts
system_logs          temp_files           node_cache           python_cache
jetbrains_cache      vscode_cache         flutter_cache        go_cache
rust_cache           ruby_cache           brew_cache           java_cache
docker_cache         android_cache        imessage_attachments maintenance
memory_purge         app_leftovers        orphaned_files       installer_files
large_old_files      ios_backups          mail_attachments     ai_models
trash
```

---

## Configuration

Set these environment variables in your `~/.zshrc` or `~/.bashrc` to customize behavior:

```bash
export MB_LOG_AGE_DAYS=14          # Delete logs older than 14 days (default: 7)
export MB_TEMP_AGE_DAYS=7          # Delete temp files older than 7 days (default: 3)
export MB_MAIL_AGE_DAYS=180        # Delete mail attachments older than 180 days (default: 90)
export MB_LOF_MIN_SIZE_MB=1000     # Large file threshold: 1 GB (default: 500 MB)
export MB_INSTALLER_AGE_DAYS=30   # Delete installers older than 30 days (default: 14)
export MB_APP_LEFTOVERS_QUERY=""   # App name to filter in the App Leftovers module
```

| Variable                 | Default   | Description                                                                                  |
| ------------------------ | --------- | -------------------------------------------------------------------------------------------- |
| `MB_LOG_AGE_DAYS`        | `7`       | Minimum age in days for log files to be eligible for deletion                                |
| `MB_TEMP_AGE_DAYS`       | `3`       | Minimum age in days for temp files to be eligible for deletion                               |
| `MB_MAIL_AGE_DAYS`       | `90`      | Minimum age in days for Mail attachment caches to be eligible for deletion                   |
| `MB_LOF_MIN_SIZE_MB`     | `500`     | Minimum file size (MB) for the Large Old Files module                                        |
| `MB_INSTALLER_AGE_DAYS`  | `14`      | Minimum age in days for installer files (`.dmg`, `.pkg`, `.iso`) to be eligible for deletion |
| `MB_APP_LEFTOVERS_QUERY` | _(empty)_ | If set, the App Leftovers module searches only for files matching this app name              |

---

## Safety and Security

MacBroom is designed so that even a bug in a cleaning module **cannot** delete system files or personal configuration data. Multiple independent safeguards enforce this at all times.

### Safeguard 1 — Hard-Coded Path Allowlist

Every deletion goes through `mb_safe_rm()` in `lib/core.sh`, which checks the target path against a hard-coded list of permitted directory prefixes before touching anything. If the path is not on the list, the deletion is refused, skipped, and written to `errors.log`. No module can bypass or override this check.

The complete list of permitted prefixes (as declared in `lib/core.sh`):

```
~/Library/Caches                          ~/Library/Logs
~/Library/Application Support             ~/Library/Containers
~/Library/Group Containers                ~/Library/Preferences
~/Library/Saved Application State         ~/Library/HTTPStorages
~/Library/Messages/Attachments            ~/Library/Messages/StickerCache
~/Library/Application Support/MobileSync
~/Library/Mail
~/Library/Developer/Xcode/DerivedData
~/Library/Developer/CoreSimulator/Caches
~/Library/Application Support/Code        ~/Library/Application Support/Cursor
~/Library/Application Support/Windsurf    ~/Library/Application Support/LM Studio
~/Library/Logs/JetBrains
~/.Trash        /Volumes/*/.Trashes/<uid> (external drive trash, current user only)
~/.npm          ~/.yarn         ~/.pnpm-store    ~/.bun
~/.gradle       ~/.m2           ~/.pub-cache     ~/.dart
~/.cargo/registry  ~/.cargo/git
~/.gem          ~/.conda        ~/.pyenv         ~/.poetry
~/.cache        ~/.cache/pip
~/.android/cache  ~/.ollama
~/.cache/huggingface  ~/.cache/torch
~/go/pkg/mod/cache    ~/Library/Caches/go-build
~/Library/Caches/CocoaPods  ~/Library/Caches/gradle  ~/Library/Caches/flutter_tools
~/Library/Caches/Homebrew   ~/Library/Android
~/Downloads     ~/Documents     ~/Desktop
~/Music         ~/Movies        ~/Pictures
~/Developer     ~/Projects      ~/src      ~/code     ~/repos    ~/workspace
$HOME (dotfile dirs only — subject to Protected Paths below)
/Library/Caches   /Library/Logs
/private/tmp      /private/var/tmp     /private/var/log
/private/var/db/diagnostics  /private/var/db/DiagnosticPipeline  /private/var/db/powerlog
```

Everything else — system directories, application binaries, network configuration — is completely unreachable.

### Safeguard 2 — Protected Path Blocklist

Even within the allowlist, a second check permanently blocks deletion of critical configuration files and directories. These paths are checked before the allowlist and always refuse deletion, regardless of any other logic:

| Protected path                                        | What it protects                                        |
| ----------------------------------------------------- | ------------------------------------------------------- |
| `~/.ssh`                                              | SSH private keys and known hosts                        |
| `~/.gnupg`, `~/.gpg`                                  | GPG encryption keys                                     |
| `~/.aws`                                              | AWS credentials and configuration                       |
| `~/.kube`                                             | Kubernetes configuration                                |
| `~/.docker`                                           | Docker credentials and daemon configuration             |
| `~/.netrc`                                            | Network authentication credentials                      |
| `~/.gitconfig`, `~/.gitignore`, `~/.gitignore_global` | Git global configuration                                |
| `~/.zshrc`, `~/.bashrc`, `~/.profile`                 | Shell configuration files                               |
| `~/.zsh_history`, `~/.bash_history`                   | Shell command history                                   |
| `~/.zsh_sessions`, `~/.bash_sessions`                 | Shell session state                                     |
| `~/.oh-my-zsh`                                        | Oh My Zsh framework                                     |
| `~/.nvm`                                              | Node Version Manager (contains installed Node versions) |
| `~/.rbenv`                                            | Ruby version manager                                    |
| `~/.pyenv`                                            | Python version manager                                  |
| `~/.asdf`                                             | Multi-language version manager                          |
| `~/.sdkman`                                           | Java SDK manager                                        |
| `~/.volta`                                            | JavaScript toolchain manager                            |
| `~/.tfenv`                                            | Terraform version manager                               |
| `~/.gvm`                                              | Go version manager                                      |
| `~/.config`                                           | XDG configuration directory                             |
| `~/.local`                                            | XDG local data directory                                |
| `~/.Spotlight-V100`                                   | Spotlight index                                         |
| `~/.fseventsd`                                        | File system events daemon                               |
| `~/.TemporaryItems`                                   | macOS temporary items                                   |
| `~/.DocumentRevisions-V100`                           | macOS document versions                                 |

### Safeguard 3 — User Whitelist

In addition to the built-in protected paths, you can define your own protected paths using the Whitelist screen (`W` key) or by editing `~/.config/macbroom/whitelist` directly. Any path you add is treated as permanently protected — `mb_safe_rm()` refuses to delete it or anything inside it.

The whitelist supports `~` expansion and strips trailing slashes automatically. Comments (lines starting with `#`) are ignored.

```bash
# ~/.config/macbroom/whitelist
~/Downloads/important-project
~/Library/Caches/my-custom-app
```

### Safeguard 4 — Risky Categories Excluded from Bulk Selection

Categories rated `[R]` (iMessage Attachments, iOS Backups, AI Models, Trash) are excluded from the `A` key on the Main screen. They must be selected individually, manually, every single time — no shortcuts.

### Safeguard 5 — Symlink Target Validation

If a path in the allowlist is a symbolic link, `mb_safe_rm()` resolves the link with `readlink` and validates that the **target** also falls inside the allowlist. A symlink inside `~/Library/Caches` that points to `/etc` is refused and logged — not silently followed. Relative symlinks are resolved against their parent directory before validation.

### Safeguard 6 — Full Deletion Log

Every deletion is written to `~/Library/Logs/MacBroom/operations.log` with a timestamp, the full path, and the size freed. Every failed or refused deletion is written to `errors.log`.

### Safeguard 7 — Zero Network Access

MacBroom makes no network connections. There is no telemetry, no update checks, no analytics, and no data collection of any kind. It is impossible for MacBroom to send anything about your files, system, or usage to any server.

### Safeguard 8 — Dry-Run Mode

Press `D` or use `--dry-run` to simulate any operation. All file listings and sizes are real; all deletions are suppressed. Use this to understand exactly what MacBroom would do before committing to anything.

### Safeguard 9 — Immutable Flag Handling

On macOS, files can be marked with the `uchg` (user-immutable) flag. If `rm -rf` fails with "Operation not permitted", MacBroom calls `chflags nouchg` to remove the flag and retries — only if the file is already within the safe allowlist. It never removes system-owned immutable flags.

### How the allowlist is enforced — a code walkthrough

For readers who want to verify the safety claims themselves, here is how the enforcement chain works:

1. Every module calls `mb_safe_rm "$path"` — there is no other deletion path in the codebase
2. `mb_safe_rm()` (in `lib/core.sh`) refuses `"/"` and `"$HOME"` immediately as a hard guard
3. External volume trash (`/Volumes/*/.Trashes/<uid>`) is explicitly allowed for the current user
4. It then iterates `MB_PROTECTED_PATHS` — refuses and returns 1 if matched
5. It then checks `MB_WHITELIST` — skips and warns if matched
6. It then iterates `MB_SAFE_PREFIXES` — refuses and logs if no prefix matches
7. If the path is a symlink, it recursively calls `mb_is_safe_path()` on the resolved target
8. Only if all checks pass does it call `rm -rf -- "$target"` (the `--` prevents path-as-flag injection)
9. The deletion is logged unconditionally after success

Both `MB_SAFE_PREFIXES` and `MB_PROTECTED_PATHS` are declared as `readonly -a` arrays at startup — no code can append to, clear, or reassign them at runtime.

---

## Why the Disk Bar Doesn't Change Immediately

After cleaning, the disk bar in MacBroom (and in Finder / About This Mac) often does not immediately show a smaller number — even though the Done screen reported several gigabytes freed. This is not a bug.

**The reason:** macOS uses APFS (Apple File System), which has a concept called _purgeable space_. When a file is deleted, the blocks it occupied are not immediately returned to the free pool. Instead, they are marked as _purgeable_ — space that macOS can reclaim when another app needs room. The actual reclaim happens in the background, triggered by memory pressure or a manual `purge` command.

**What the numbers mean:**

- **Total Freed** on the Done screen = the accurate total of what was deleted from disk
- **Disk bar** = what macOS has physically reclaimed so far (may lag by minutes to an hour)
- **APFS Purgeable** on the Main screen = space macOS is holding as reclaimable

Disk stats in Finder typically update within minutes to an hour after a large clean. Pressing any key on the Done screen rescans and refreshes MacBroom's own disk bar.

---

## Project Structure

```
MacBroom/
├── macbroom                         # Main script: CLI router, module registry, TUI event loop
├── install.sh                       # Installer / uninstaller
├── lib/
│   ├── core.sh                      # mb_safe_rm, path allowlist, whitelist system, size formatting, logging
│   ├── disk.sh                      # APFS disk stats: mb_disk_used_kb, mb_disk_total_kb
│   ├── ui.sh                        # All seven TUI screens, status dashboard, whitelist UI, key reader
│   ├── undo.sh                      # Session recording and deletion log
│   └── cron.sh                      # launchd plist management
├── modules/                         # One file per cleaning category (29 total)
│   ├── user_caches.sh
│   ├── browser.sh
│   ├── dev_tools.sh
│   ├── project_artifacts.sh         # node_modules, __pycache__, .next, .build, etc.
│   ├── system_logs.sh
│   ├── temp_files.sh
│   ├── node_cache.sh
│   ├── python_cache.sh
│   ├── jetbrains_cache.sh
│   ├── vscode_cache.sh
│   ├── flutter_cache.sh
│   ├── go_cache.sh
│   ├── rust_cache.sh
│   ├── ruby_cache.sh
│   ├── brew_cache.sh                # Homebrew download cache + cleanup + autoremove
│   ├── java_cache.sh
│   ├── docker_cache.sh
│   ├── android_cache.sh
│   ├── imessage_attachments.sh
│   ├── maintenance.sh               # DNS flush, font cache, APFS snapshots, Launch Services, TouchID
│   ├── memory_purge.sh
│   ├── app_leftovers.sh
│   ├── orphaned_files.sh            # Bundle orphans + orphaned dotfile directories
│   ├── installer_files.sh           # .dmg, .pkg, .iso cleanup
│   ├── large_old_files.sh
│   ├── ios_backups.sh
│   ├── mail_attachments.sh
│   ├── ai_models.sh
│   └── trash.sh
└── tests/                           # bats-core test suite (59 tests)
    ├── test_core.bats               # mb_safe_rm, mb_is_safe_path, symlink validation, mb_format_bytes
    ├── test_orphaned_files.bats     # _is_system_bundle, _is_likely_bundle_dir, false positive exclusions
    └── test_maintenance.bats        # dry-run output, snapshot preview, result_file writes
```

---

## Running the Tests

MacBroom includes a [bats-core](https://github.com/bats-core/bats-core) test suite covering the core safety layer and critical module logic. All 59 tests pass on macOS 11+.

Install bats-core if you don't have it:

```bash
brew install bats-core
```

Run all tests from the project root:

```bash
bats tests/
```

Expected output:

```
 ✓ safe path: exact prefix is allowed
 ✓ safe path: subpath of prefix is allowed
 ✓ safe path: path outside allowlist is refused
 ...
59 tests, 0 failures
```

**What the tests cover:**

| Test file                  | What it tests                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `test_core.bats`           | `mb_is_safe_path` allowlist enforcement, protected path blocking, HOME itself refused, trailing slash normalization, symlink target validation (safe link, unsafe link, link to `.ssh`), `mb_safe_rm` delete/refuse/idempotent/root/HOME behavior, `mb_format_bytes` formatting for all size ranges                                                                                                                                                                                                                                          |
| `test_orphaned_files.bats` | `_is_system_bundle` exclusions for all vendor prefixes (`com.apple.*`, `com.google.Keystone`, `com.microsoft.autoupdate`, `com.adobe.acc`, `com.crashlytics.*`, `io.fabric.*`, `com.bugsnag.*`, `com.sentry.*`); user apps that must NOT be excluded (`com.spotify.client`, `com.google.Chrome`, `org.mozilla.firefox`, `io.cursor.app`, `net.whatsapp.WhatsApp`); `_is_likely_bundle_dir` pattern matching for `com.*`, `org.*`, `io.*`, `net.*`, plain names, numeric names, hidden dirs; edge cases for partial matches and empty strings |
| `test_maintenance.bats`    | `maintenance_scan` always returns 0; dry-run exits 0 with no snapshots; output contains "Flush DNS", "Font Cache", "Launch Services"; "none found" message with no snapshots; snapshot count display with 2 simulated snapshots; irreversible warning when snapshots present; `result_file` written correctly; non-dry-run writes 0 to result_file                                                                                                                                                                                           |

---

## Module API — Adding Your Own Module

Each module file implements up to four Bash functions. Create `modules/<name>.sh` with these signatures:

```bash
# Required — print total reclaimable size in KB to stdout
<name>_scan()

# Required — print lines of "size_kb|label|path", sorted largest first
<name>_list()

# Required — accept (dry_run, result_file); write freed KB to result_file
<name>_clean()

# Optional — print a command name; module is skipped if the command is not in PATH
<name>_requires()
```

Then `source` the file in `macbroom` and add one entry to each registry array:

| Array              | Purpose                                                                            |
| ------------------ | ---------------------------------------------------------------------------------- |
| `MB_MOD_NAMES`     | Internal ID used by CLI commands (e.g. `brew_cache`)                               |
| `MB_MOD_LABELS`    | Display name shown in the TUI (e.g. `"Homebrew Cache"`)                            |
| `MB_MOD_DESCS`     | One-line description shown in the info bar                                         |
| `MB_MOD_EFFECTS`   | One sentence explaining what happens after deletion                                |
| `MB_MOD_SAFETY`    | `"safe"`, `"moderate"`, or `"risky"`                                               |
| `MB_MOD_SCAN_FNS`  | Reference to the `_scan` function                                                  |
| `MB_MOD_LIST_FNS`  | Reference to the `_list` function                                                  |
| `MB_MOD_CLEAN_FNS` | Reference to the `_clean` function                                                 |
| `MB_MOD_DEFERRED`  | `1` to skip at startup and scan lazily when Preview opens; `0` to scan immediately |

All arrays must have the same length. Array indices are used as the module identifier throughout the TUI.

**Example — a minimal module:**

```bash
# modules/my_cache.sh
my_cache_requires() { printf 'mytool'; }

my_cache_scan() {
    local dir="$HOME/.mytool/cache"
    [[ -d "$dir" ]] || { printf '0'; return; }
    mb_size_kb "$dir"
}

my_cache_list() {
    local dir="$HOME/.mytool/cache"
    [[ -d "$dir" ]] || return 0
    find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null | while IFS= read -r -d '' f; do
        local s; s=$(mb_size_kb "$f")
        printf '%d|%s|%s\n' "$s" "$(basename "$f")" "$f"
    done | sort -t'|' -k1 -rn
}

my_cache_clean() {
    local dry_run="${1:-false}" result_file="${2:-}"
    local cleaned_kb=0
    local dir="$HOME/.mytool/cache"
    if [[ "$dry_run" == "true" ]]; then
        mb_dim "  would remove: $dir  ($(mb_format_kb "$(mb_size_kb "$dir")"))"
        cleaned_kb=$(mb_size_kb "$dir")
    else
        local s; s=$(mb_size_kb "$dir")
        mb_safe_rm "$dir" && cleaned_kb=$s
    fi
    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
```

Then in `macbroom`, add `source modules/my_cache.sh` and append one entry to each of the 9 registry arrays.

**Important rules for modules:**

- Always call `mb_safe_rm` for deletions — never call `rm` directly
- Never modify `MB_SAFE_PREFIXES` or `MB_PROTECTED_PATHS` (they are `readonly`)
- Print size in KB to stdout from `_scan` — no other output
- Write freed KB as a plain integer to `$result_file` from `_clean`
- Use `mb_format_kb` and `mb_format_bytes` for human-readable sizes in messages
- Use `mb_ok`, `mb_warn`, `mb_error`, `mb_dim` for any status output during cleaning
- Add the new safe path to `MB_SAFE_PREFIXES` if the module targets a directory not already on the list (and ensure `MB_PROTECTED_PATHS` covers any sensitive sub-paths)

---

## Troubleshooting

**Project Artifacts or Large Old Files shows `—` instead of a size**

This is expected. Both modules use `find` across potentially large directory trees, which takes too long to run alongside the other scans at startup. Press `→` to open the Preview screen — the scan runs while the spinner plays. When you press `←` to return, the real size replaces `—` and the size bar appears.

**A module shows 0 bytes**

Either the tool required by that module is not installed, or its data directory does not exist yet:

- `brew_cache`: requires `brew` in `$PATH`
- `docker_cache`: requires Docker Desktop installed and the Docker daemon running
- `go_cache`: requires `go` in `$PATH`
- `flutter_cache`: requires `flutter` in `$PATH`

Modules skip themselves automatically when their requirement is absent — this is expected behavior.

**The Status dashboard shows stale data**

Press `R` to refresh. The dashboard collects metrics once when you open it and does not auto-refresh. `top -l 1` takes about one second to sample.

**A whitelisted path is still being shown in a module's Preview**

The whitelist protects paths from _deletion_ — it does not hide them from Preview listings. The module will still detect and list the path, but `mb_safe_rm` will refuse to delete it and print a warning when you press Enter. This is intentional: you can still see what's there without any risk.

**The TUI looks garbled or misaligned**

- Resize your terminal window — MacBroom redraws the entire interface on every resize
- Confirm your terminal's character encoding is UTF-8
- Confirmed working: macOS Terminal.app, iTerm2, Ghostty, Warp, Alacritty

**Some paths are skipped even though they exist**

MacBroom only deletes paths on its allowlist. If a module finds files in a path that is not on the list, those files are skipped and logged to `~/Library/Logs/MacBroom/errors.log`. Check that file for the specific reason.

**Cleaning requires Full Disk Access**

Folders like `~/Library/Containers`, `~/Library/Mail`, and `~/Library/Messages` are protected by macOS SIP and require Full Disk Access:

`System Settings → Privacy & Security → Full Disk Access → add your terminal app`

**Permission denied on `/private/tmp`**

Files in `/private/tmp` owned by the system or other users are skipped. MacBroom does not use `sudo` for temp file cleanup. Your own temp files are cleaned; system-owned ones are left alone.

**Terminal closes with "Saving session... [Process completed]"**

This is macOS Terminal.app showing zsh's normal logout message. It is not a crash. It means MacBroom exited cleanly (e.g., you pressed `Q`). If this appears when you did not press `Q`, open MacBroom from iTerm2 or Ghostty — those terminals keep the window open after process exit so you can read any error output.

**Disk bar does not update after cleaning**

Expected APFS behavior. See [Why the Disk Bar Doesn't Change Immediately](#why-the-disk-bar-doesnt-change-immediately). The Total Freed counter is accurate; the disk bar reflects what macOS has physically reclaimed so far.

**The `A` key selected a Risky `[R]` category**

This cannot happen. The `A` key explicitly skips every module marked `risky` in the safety registry. Risky categories require a manual `Space` key press to select.

**TouchID for sudo is not working after running Maintenance**

TouchID sudo support requires macOS 13 Ventura or later. On earlier versions, the step is silently skipped. Also check that your Mac has a Touch ID sensor — Macs without Touch ID (e.g., Mac Pro, some Mac minis) cannot use this feature. Finally, verify that `/etc/pam.d/sudo_local` contains the `pam_tid.so` line:

```bash
cat /etc/pam.d/sudo_local
# should contain: auth       sufficient     pam_tid.so
```

**`brew autoremove` removed a package I didn't expect**

`brew autoremove` removes packages that were installed only as dependencies of formulae you have since removed. If you want to keep a package that `autoremove` would remove, mark it as explicitly installed:

```bash
brew install <package>   # re-installs and marks it as explicitly requested
```

---

## License

MIT License. Copyright (c) 2026 AarontheGalaxy.

---

_MacBroom v1.2.0 — built for macOS power users who want fast, transparent, and safe disk cleanup without black-box GUIs or third-party runtimes._
