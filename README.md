# MacBroom

MacBroom is an interactive terminal disk cleaner for macOS, written entirely in Bash. It scans 26 categories of junk in parallel, shows you exactly what it found, lets you pick precisely what to delete — and never touches anything outside a hard-coded list of safe directories.

No Homebrew. No Python. No Ruby. No installation required beyond cloning the repo.

```
  MacBroom
──────────────────────────────────────────────────────────────────────────────
Disk Usage: ■■■■■■■■■■■■□□□□  892.4 GB / 994.7 GB (90%)
APFS Purgeable: 12.3 GB
──────────────────────────────────────────────────────────────────────────────
▶ ○ [S] User App Caches    ·····  ■■■■■■□□□□      2.1 GB   ← bold (cursor)
  ○ [S] Browser Caches     ·····  ■■■■□□□□□□      1.3 GB   ← dim
  ● [M] Developer Tools    ·····  ■■■■■■□□□□      1.8 GB   ← green (selected)
  ○ [S] Node.js & JS       ·····  ■■■□□□□□□□    890 MB
  ○ [S] Python & pip       ·····  ■■□□□□□□□□    540 MB
  ○ [M] JetBrains IDEs     ·····  ■■■■□□□□□□      1.1 GB
  ○ [M] System & App Logs  ·····  ■□□□□□□□□□    210 MB
  ○ [S] Temp Files         ·····  ■□□□□□□□□□    180 MB
  ○ [R] Trash              ·····  ■■□□□□□□□□    640 MB
  [S] Safe  · Application cache directories in ~/Library/Caches  (1-9/26)
──────────────────────────────────────────────────────────────────────────────
 ↑↓ Navigate  Space Toggle  → Preview  Enter Clean  A All  N None  Q Quit
```

---

## Table of Contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [How to Launch](#how-to-launch)
4. [Understanding the Interface](#understanding-the-interface)
   - [The Scanning Screen](#the-scanning-screen)
   - [The Main Screen](#the-main-screen)
   - [The Preview Screen](#the-preview-screen)
   - [The Cleaning Screen](#the-cleaning-screen)
   - [The Done Screen](#the-done-screen)
5. [How to Clean — Step by Step](#how-to-clean--step-by-step)
   - [Quick Clean: delete an entire category](#quick-clean-delete-an-entire-category)
   - [Precise Clean: choose individual files](#precise-clean-choose-individual-files)
   - [The connection between the two modes](#the-connection-between-the-two-modes)
6. [Complete Keyboard Reference](#complete-keyboard-reference)
7. [All 26 Cleaning Modules](#all-26-cleaning-modules)
8. [Advanced Features](#advanced-features)
9. [CLI Reference](#cli-reference)
10. [Configuration](#configuration)
11. [Safety and Security](#safety-and-security)
12. [Why the Disk Bar Doesn't Change Immediately](#why-the-disk-bar-doesnt-change-immediately)
13. [Project Structure](#project-structure)
14. [Troubleshooting](#troubleshooting)
15. [License](#license)

---

## Requirements

| Requirement | Details |
| ----------- | ------- |
| macOS | 11 Big Sur or later |
| Bash | 3.2+ (pre-installed on every Mac) |
| Terminal | Any terminal with UTF-8 and 256-color support — Terminal.app, iTerm2, Ghostty, Warp, Alacritty all work |
| Disk space | Less than 1 MB for the entire project |

> **Recommended:** Go to `System Settings → Privacy & Security → Full Disk Access` and add your terminal app to the list. This allows MacBroom to scan protected folders like `~/Library/Mail` and `~/Library/Containers`. Without it, some modules will report smaller sizes than reality.

---

## Installation

### Option A — Clone and install (recommended)

```bash
git clone https://github.com/AarontheGalaxy/MacBroom.git
cd MacBroom
bash install.sh
```

This copies the project to `~/.macbroom/` and creates a launcher at `/usr/local/bin/macbroom`. No `sudo` needed. After this you can type `macbroom` from any directory.

To uninstall:

```bash
bash ~/.macbroom/install.sh --uninstall
```

### Option B — Run directly without installing

```bash
cd MacBroom
bash macbroom
```

Everything works the same. You just need to be in the project directory.

---

## How to Launch

```bash
macbroom
```

That's it. MacBroom immediately starts scanning your Mac and opens the interactive interface.

---

## Understanding the Interface

MacBroom has five screens. You move between them automatically as you work. Here is what each one looks like and what it does.

---

### The Scanning Screen

This is the first thing you see every time MacBroom starts. It scans all 26 categories at the same time (in parallel), so the total wait is only as long as the slowest scan — usually a few seconds.

```
  MacBroom
──────────────────────────────────────────────────────────────────────────────


              ⠙  Scanning JetBrains IDE Caches...


──────────────────────────────────────────────────────────────────────────────
Please wait while we analyze your system...
```

- The spinner `⠙` animates while scanning is in progress.
- The label in the middle shows which category is still being measured.
- You cannot do anything here — just wait. It finishes quickly.
- When all scans are done, MacBroom automatically switches to the Main screen.

> **Note on Large Old Files:** This module scans your entire home folder with `find`, which can take many seconds on a large disk. MacBroom skips it at startup to keep the initial scan fast. In the Main screen it shows `—` instead of a size. The actual scan runs the moment you open its Preview screen (`→`). MacBroom totals the item sizes while loading Preview and writes the result back — so when you press `←` to return to the Main screen, the real size appears in place of `—`.

---

### The Main Screen

This is the central control panel. It lists all 26 cleaning categories with their sizes, safety ratings, and selection state.

```
  MacBroom
──────────────────────────────────────────────────────────────────────────────
Disk Usage: ■■■■■■■■■■■■□□□□  892.4 GB / 994.7 GB (90%)
APFS Purgeable: 12.3 GB
──────────────────────────────────────────────────────────────────────────────
▶ ● [S] User App Caches  ·······  ■■■■■■□□□□      2.1 GB   ← GREEN BOLD (selected + cursor)
  ○ [S] Browser Caches   ·······  ■■■■□□□□□□      1.3 GB   ← dim
  ● [M] Developer Tools  ·······  ■■■■■■□□□□      1.8 GB   ← GREEN (selected)
  ○ [S] Node.js & JS     ·······  ■■■□□□□□□□    890 MB     ← dim
  ○ [S] Python & pip     ·······  ■■□□□□□□□□    540 MB
  ○ [M] JetBrains IDEs   ·······  ■■■■□□□□□□      1.1 GB
  ○ [M] System & App Logs ······  ■□□□□□□□□□    210 MB
  ○ [S] Temp Files       ·······  ■□□□□□□□□□    180 MB
  ○ [M] Large Old Files  ·······                       —   ← not scanned at startup
  ○ [R] Trash            ·······  ■■□□□□□□□□    640 MB
  [S] Safe  · Application cache directories in ~/Library/Caches  (1-10/26)
──────────────────────────────────────────────────────────────────────────────
 ↑↓ Navigate  Space Toggle  → Preview  Enter Clean  A All  N None  Q Quit
```

**What each part of a row means:**

| Symbol | Meaning |
| ------ | ------- |
| `▶` | The cursor — this is the row you are currently on |
| `○` | This category is not selected |
| `●` | This category is selected for cleaning |
| `[S]` | Safe — caches that apps rebuild automatically, no side effects |
| `[M]` | Moderate — safe to remove, but some apps may be slower on first launch after |
| `[R]` | Risky — permanently deletes user data; must be selected manually |
| `·····` | Dot leader — visually connects the module name to its size bar so you can track which number belongs to which row |
| `■■■□□□` | Size bar — shows size relative to the largest category |
| Number on right | Total reclaimable size for this category |
| `—` | Size not yet scanned (see Large Old Files below) |

**The size number changes color** to communicate selection state at a glance:

| Size color | Meaning |
| ---------- | ------- |
| **Bold white** | The cursor is on this row (not selected) |
| **Green** | This category is selected (`●`) |
| **Bold green** | Selected AND the cursor is on this row |
| Dim | Not selected, not the cursor |

**The info bar** (second row from bottom): Shows the safety badge in color (`[S]` green / `[M]` yellow / `[R]` red), followed by a one-line description of whatever category your cursor is on, and a scroll position like `(1-10/26)` when the list is taller than your terminal window. This means you always know the safety level of the highlighted module without looking at the left column.

**The disk bar** at the top: Reads from the APFS volume and matches exactly what Finder and About This Mac report. Turns yellow above 35% usage, red above 70%.

**APFS Purgeable**: Space macOS is holding as reclaimable (Time Machine snapshots, iCloud-backed files). This is separate from what MacBroom cleans. Shown only when macOS reports a non-zero value.

---

### The Preview Screen

Opened by pressing `→` on any category in the Main screen. Shows the exact list of files and folders that category contains, so you can choose what to delete individually.

**When you first open Preview with nothing pre-selected:**

```
  MacBroom  ›  Browser Caches
──────────────────────────────────────────────────────────────────────────────
  Cache directories for Safari, Chrome, Firefox, and other browsers
✓ Safe: Browsers re-download page assets — slightly slower first load after clean
──────────────────────────────────────────────────────────────────────────────
▶ [ ] com.apple.Safari                                              1.2 GB
  [ ] com.google.Chrome                                           340 MB
  [ ] org.mozilla.firefox                                          120 MB
  [ ] com.microsoft.edgemac                                         80 MB
  [ ] com.brave.Browser                                             45 MB

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
  [✓] com.google.Chrome                                           340 MB
  [✓] org.mozilla.firefox                                          120 MB
  [✓] com.microsoft.edgemac                                         80 MB
  [✓] com.brave.Browser                                             45 MB

──────────────────────────────────────────────────────────────────────────────
 ← Back  ↑↓ Navigate  Space Toggle  / Filter  Enter Delete 5 selected  Q Quit
```

Everything is pre-selected because the category was already marked `●`. You can now uncheck anything you want to keep.

**What each part means:**

| Symbol | Meaning |
| ------ | ------- |
| `[ ]` | This file/folder is not selected — it will NOT be deleted |
| `[✓]` | This file/folder is selected — it WILL be deleted when you press Enter |
| `▶` | Your cursor position |

**The footer changes** depending on whether anything is selected:
- No items selected → `Space to select files — nothing deleted until you select`
- Items selected → `Enter Delete N selected` (where N is the count)

**The header area** (lines below the title) shows:
- A description of what this category cleans
- A safety note in color: green for Safe, yellow for Moderate, red for Risky — with a one-sentence explanation of what happens after deletion

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

| Symbol | Meaning |
| ------ | ------- |
| `✓` green | This category is done |
| `⠙` cyan (animated) | This category is currently being cleaned |
| `○` dim | This category is waiting |

The progress bar at the bottom shows how many categories have finished out of the total selected.

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

> **Why doesn't the disk bar change immediately?** macOS uses APFS, which marks deleted blocks as "purgeable" rather than immediately freeing them. The Total Freed number is correct; the disk bar just takes a little time to reflect it. See [Why the Disk Bar Doesn't Change Immediately](#why-the-disk-bar-doesnt-change-immediately) for the full explanation.

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

**Step 4** — Repeat steps 2–3 for any other categories you want to clean. You can select as many as you want.

**Step 5** — Press `Enter`. MacBroom cleans every selected category and shows the Done screen.

**Shortcut:** Press `A` to select all Safe and Moderate categories at once (Risky ones are excluded). Press `N` to deselect everything.

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

**Step 2** — Use `↑` / `↓` to navigate to the category you want to inspect.

**Step 3** — Press `→` (right arrow). The Preview screen opens and lists every file and folder inside that category, sorted largest first.

```
  ▶ ○ [S] Browser Caches  ·······  ■■■■□□□□□□    1.3 GB   ← bold (cursor only)

  → (press right arrow)
```

**Step 4** — Browse the list with `↑` / `↓`. Each row shows a file or folder name and its size.

**Step 5** — Press `Space` on any item to check or uncheck it.

```
  [ ] com.apple.Safari           1.2 GB   ← not selected, will NOT be deleted
  [✓] com.google.Chrome        340 MB   ← selected, WILL be deleted
  [ ] org.mozilla.firefox        120 MB   ← not selected, will NOT be deleted
```

> **Important:** Nothing is deleted until you explicitly check something and press `Enter`. The footer shows exactly how many items are selected: `Enter Delete 1 selected`. If the footer says `Space to select files — nothing deleted until you select`, that means zero items are checked and pressing Enter will do nothing.

**Step 6** — When you've selected everything you want to delete, press `Enter`. Only the checked items are deleted.

**Step 7** — Press `←` (left arrow) at any time to go back to the Main screen without deleting anything.

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

Here is how it works:

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
- `A` then `Enter` = delete everything in all safe/moderate categories at once
- `A` then `→` on a category = review and remove individual items before committing
- `→` without selecting = browse freely and pick exactly what you want

---

## Complete Keyboard Reference

### Main Screen

| Key | Action |
| --- | ------ |
| `↑` or `k` | Move cursor up one row |
| `↓` or `j` | Move cursor down one row |
| `Space` | Toggle the highlighted category on (`●`) or off (`○`) |
| `→` or `l` | Open the Preview screen for the highlighted category |
| `Enter` | Start cleaning all selected (`●`) categories |
| `A` | Select all Safe `[S]` and Moderate `[M]` categories (Risky `[R]` are skipped) |
| `N` | Deselect all categories |
| `D` | Toggle Dry-Run mode on/off (no files are deleted in dry-run) |
| `Q` | Quit MacBroom |

### Preview Screen

| Key | Action |
| --- | ------ |
| `↑` or `k` | Move cursor up one row |
| `↓` or `j` | Move cursor down one row |
| `Space` | Check `[✓]` or uncheck `[ ]` the highlighted item |
| `A` | Check all currently visible items |
| `N` | Uncheck all currently visible items |
| `Enter` | **If cursor is on an unchecked folder:** enter it (drill-down). **If any items are checked:** delete all checked items. |
| `←` or `h` | Go back one level (if inside a subfolder) or return to Main screen |
| `Esc` | If a filter is active: clear the filter. Otherwise: return to Main screen. |
| `/` | Enter filter mode — type to search items by name |
| `Backspace` | Delete the last character of the search filter |
| `Q` | Quit MacBroom |

### Done Screen

| Key | Action |
| --- | ------ |
| Any key (except Q) | Rescan all categories and return to Main screen with updated sizes |
| `Q` | Quit MacBroom |

### Dry-Run Mode

Press `D` on the Main screen to activate Dry-Run mode. The title bar changes to `MacBroom (DRY RUN)`. In this mode:

- Scanning and all file listings are real — you see actual sizes and actual file names
- The Preview screen works normally
- Pressing `Enter` to clean **does not delete anything**
- The Done screen shows how much *would have been* freed
- Press `D` again to turn Dry-Run mode off

Dry-Run is useful for understanding exactly what MacBroom would do before committing to a real clean.

---

## All 26 Cleaning Modules

### Safety Ratings

Every category has a badge that tells you how safe it is to clean. These badges are also shown in the info bar at the bottom of the main screen as you navigate.

| Badge | Name | What it means |
| ----- | ---- | -------------- |
| `[S]` **green** | **Safe** | Pure caches that apps rebuild automatically. No data loss, no slowdown after cleaning. |
| `[M]` **yellow** | **Moderate** | Safe to remove, but some apps may be slightly slower on their first launch after cleaning while they rebuild indexes or re-download dependencies. |
| `[R]` **red** | **Risky** | Permanently deletes user data — attachments, backups, AI models. May not be recoverable. **Excluded from the `A` key and `macbroom clean --all`. Must be selected manually every time.** |

---

### 1. User App Caches — `user_caches` `[S]`

**What it cleans:** Every application cache folder inside `~/Library/Caches`. This is usually the single largest source of reclaimable space on any Mac. Every app uses this folder to store temporary data — downloaded thumbnails, compiled resource files, search indexes, rendered previews. All of it is regenerated automatically when the app needs it again.

**After cleaning:** Apps recreate their caches on next use. You may notice a brief slowdown the first time you open each app, but nothing is permanently lost.

---

### 2. Browser Caches — `browser` `[S]`

**What it cleans:** Cache folders for:
- Safari (`com.apple.Safari`)
- Google Chrome (`com.google.Chrome`)
- Arc Browser (`company.thebrowser.Browser`)
- Mozilla Firefox (`org.mozilla.firefox`)
- Microsoft Edge (`com.microsoft.edgemac`)
- Brave Browser (`com.brave.Browser`)
- Opera and other Chromium-based browsers

**After cleaning:** Web pages will load slightly slower on the first visit after cleaning, while the browser re-downloads page assets (images, CSS, JavaScript). After that, browsing returns to normal speed.

---

### 3. Developer Tool Caches — `dev_tools` `[M]`

**What it cleans:**
- Xcode DerivedData (`~/Library/Developer/Xcode/DerivedData`) — compiled build artifacts and intermediate files generated during iOS/macOS development
- iOS Simulator caches (`~/Library/Developer/CoreSimulator/Caches`) — device runtime images cached by the Simulator

**After cleaning:** Xcode will recompile your project from scratch on the next build, which takes longer than usual. The Simulator re-downloads device images as needed. Your source code and project files are never touched.

---

### 4. System & App Logs — `system_logs` `[M]`

**What it cleans:** Log files and crash reports in `~/Library/Logs` that are older than `MB_LOG_AGE_DAYS` days (default: 7 days). Recent logs are always preserved.

**After cleaning:** Old logs are gone. Apps continue writing new logs normally. No impact on running applications.

---

### 5. Temp Files — `temp_files` `[S]`

**What it cleans:** Temporary files in `/private/tmp` and `/private/var/tmp` that are older than `MB_TEMP_AGE_DAYS` days (default: 3 days). These are files that apps create for short-lived purposes and typically never clean up themselves.

**After cleaning:** No impact. macOS and apps create new temp files as needed.

---

### 6. Node.js & JS Caches — `node_cache` `[S]`

**What it cleans:**
- npm global cache (`~/.npm`)
- Yarn cache (`~/.yarn` / `~/.cache/yarn`)
- pnpm content-addressable store (`~/.pnpm-store`)
- Bun package cache (`~/.bun/install/cache`)
- node-gyp build cache

**After cleaning:** Package managers re-download packages from the registry on the next `npm install` / `yarn install` / etc. Your project `node_modules` folders and `package-lock.json` files are not touched — only the global download cache is removed.

---

### 7. Python & pip Caches — `python_cache` `[S]`

**What it cleans:**
- pip download cache (`~/.cache/pip`)
- conda package cache (`~/.conda/pkgs`)
- Poetry cache (`~/.poetry/cache` or `~/.cache/pypoetry`)
- pyenv build artifacts (`~/.pyenv/cache`)

**After cleaning:** pip, conda, and poetry re-download packages from their registries on next install. Your virtual environments and installed packages are not affected.

---

### 8. JetBrains IDE Caches — `jetbrains_cache` `[M]`

**What it cleans:** Cache and log directories for all JetBrains products found in `~/Library/Caches` and `~/Library/Logs`:
- IntelliJ IDEA, PyCharm, WebStorm, GoLand, CLion, DataGrip, Rider
- Android Studio (JetBrains distribution)
- PhpStorm, RubyMine, AppCode, and any other JetBrains IDE

**After cleaning:** The IDE rebuilds its internal indexes and caches the next time it opens. For large projects, IntelliJ-based IDEs can take several minutes to re-index. Your project files and IDE settings are never touched.

---

### 9. VS Code Caches — `vscode_cache` `[S]`

**What it cleans:** Cache directories for:
- Visual Studio Code (`~/Library/Application Support/Code/Cache`, `CachedData`, `CachedExtensionVSIXs`, etc.)
- Cursor (`~/Library/Application Support/Cursor/Cache`, etc.)
- Windsurf (`~/Library/Application Support/Windsurf/Cache`, etc.)

**After cleaning:** Each editor regenerates its caches on next launch. Your extensions, settings, and workspace state are not affected.

---

### 10. Flutter & Dart Caches — `flutter_cache` `[S]`

**What it cleans:**
- Flutter pub package cache (`~/.pub-cache`)
- Dart tool cache (`~/.dart`)
- Flutter tools stamp cache (`~/Library/Caches/flutter_tools`)

**After cleaning:** `flutter pub get` or `dart pub get` re-downloads packages from pub.dev on the next build. Your project's `pubspec.lock` and `lib/` source files are not touched.

---

### 11. Go Module Cache — `go_cache` `[S]`

**What it cleans:**
- Go module download cache (`~/go/pkg/mod/cache`)
- Go build cache (`~/Library/Caches/go-build`)

**After cleaning:** `go build` re-downloads modules from the Go module proxy and recompiles from source on the next build. Your `go.mod`, `go.sum`, and source files are untouched.

---

### 12. Rust & Cargo Cache — `rust_cache` `[S]`

**What it cleans:**
- Cargo registry index and downloaded crate sources (`~/.cargo/registry`)
- Cargo git source cache (`~/.cargo/git`)

**After cleaning:** Cargo re-downloads crates from crates.io on the next `cargo build`. Your project's `target/` directory (compiled output) and `Cargo.lock` are not touched.

---

### 13. Ruby & CocoaPods Cache — `ruby_cache` `[S]`

**What it cleans:**
- RubyGems download cache (`~/.gem/cache`)
- CocoaPods download cache (`~/Library/Caches/CocoaPods`)

**After cleaning:** Bundler re-downloads gems on next `bundle install`. CocoaPods re-downloads pod sources on next `pod install`. Your installed gems and pods are not affected.

---

### 14. Java & Gradle Cache — `java_cache` `[S]`

**What it cleans:**
- Gradle module cache (`~/.gradle/caches`)
- Gradle daemon files (`~/.gradle/daemon`)
- Gradle build cache (`~/Library/Caches/gradle`)

**After cleaning:** Gradle re-downloads JARs and dependencies from Maven Central on the next build. The first build after cleaning may be significantly slower. Your project source files and `build.gradle` are not touched.

---

### 15. Docker Build Cache — `docker_cache` `[M]`

**What it cleans:**
- Docker BuildKit cache layers (equivalent to `docker builder prune`)
- Dangling (untagged) images that are not referenced by any container

**Requires:** Docker Desktop must be installed and running.

**After cleaning:** The next `docker build` rebuilds all image layers from scratch, which is slower than a cached build. Running containers and named/tagged images are never affected.

---

### 16. Android SDK Cache — `android_cache` `[S]`

**What it cleans:**
- Android SDK temporary files and download cache (`~/Library/Android`)
- Android emulator cache (`~/.android/cache`)

**After cleaning:** Android Studio regenerates SDK indexes on the next project sync. Your SDK components, AVD (emulator) configurations, and project files are not affected.

---

### 17. iMessage Attachments — `imessage_attachments` `[R]`

**What it cleans:**
- `~/Library/Messages/Attachments` — photos, videos, audio files, and documents received in the Messages app
- `~/Library/Messages/StickerCache` — downloaded sticker packs

**After cleaning:** The files are removed from local storage. In most cases, they remain visible in the conversation as thumbnails and can be re-downloaded from iCloud if iMessage sync is enabled. If iCloud Messages is disabled, files may be permanently unrecoverable.

> **This is a Risky `[R]` module.** Always open Preview (`→`) to review the individual attachments and their sizes before deleting.

---

### 18. Maintenance Tasks — `maintenance` `[M]`

**What it does** (runs as a batch — no individual files to preview):

1. **DNS cache flush** — runs `dscacheutil -flushcache` and `killall -HUP mDNSResponder`. Clears stale DNS entries that can cause websites to not resolve correctly.
2. **Font cache rebuild** — runs `atsutil databases -remove`. Forces macOS to rebuild the font database, which fixes font rendering issues. Takes effect after logout.
3. **APFS local snapshot purge** — deletes all Time Machine local snapshots via `tmutil deletelocalsnapshots`. These snapshots can quietly occupy several GB.
4. **Launch Services reset** — re-registers all apps, fixing broken "Open With" menus and stale file associations.

**Note:** Because this module runs system commands rather than deleting files, the Preview screen shows nothing to select. Selecting it and pressing `Enter` runs all four tasks automatically.

---

### 19. Memory Purge — `memory_purge` `[M]`

**What it does:** Calls `memory_pressure -l critical` (or `purge` as fallback) to flush inactive memory pages and return them to the free pool.

**Important:** This module frees RAM, not disk space. It will always report 0 bytes freed on the Done screen.

**After running:** Apps that had data sitting in inactive memory may need to reload it, causing a brief slowdown on first use.

---

### 20. App Leftovers — `app_leftovers` `[M]`

**What it cleans:** Support files, preference files, and caches left behind by applications that have been uninstalled. Searches inside:
- `~/Library/Application Support`
- `~/Library/Caches`
- `~/Library/Preferences`
- `~/Library/Containers`
- `~/Library/Group Containers`

**Targeted search:** Set the `MB_APP_LEFTOVERS_QUERY` environment variable to search for a specific app's leftovers:

```bash
MB_APP_LEFTOVERS_QUERY="Spotify" macbroom list app_leftovers
MB_APP_LEFTOVERS_QUERY="Spotify" macbroom clean app_leftovers
```

The search is case-insensitive and matches partial names. Minimum 3 characters.

**After cleaning:** No impact — these are files from apps that are no longer installed.

---

### 21. Orphaned App Files — `orphaned_files` `[M]`

**What it cleans:** Directories in standard app data locations whose names match a bundle ID pattern (e.g., `com.company.AppName`) but have **no corresponding application installed** in `/Applications` or `~/Applications`.

MacBroom queries Spotlight's `mdfind` to get the full list of installed bundle IDs and compares them against directory names. Anything not matching a known installed app is flagged as an orphan.

Searches:
- `~/Library/Application Support`
- `~/Library/Containers`
- `~/Library/Group Containers`
- `~/Library/Saved Application State`
- `~/Library/Caches` (bundle-style names only: `com.*`, `org.*`, `io.*`, etc.)

Returns up to 50 results sorted by size, largest first.

> **Always use Preview (`→`) before cleaning this module.** Some apps use a bundle ID that differs from their visible `.app` name, and could be incorrectly flagged as orphans. Review the list carefully.

---

### 22. Large Old Files — `large_old_files` `[M]`

**What it cleans:** Files larger than `MB_LOF_MIN_SIZE_MB` MB (default: 500 MB) that have not been accessed in more than 180 days. Searches inside:
- `~/Downloads`
- `~/Documents`
- `~/Desktop`
- `~/Music`
- `~/Movies`
- `~/Pictures`

**Why it shows `—` on the Main screen:** This module uses `find` to walk your entire home folder, which can take many seconds on large disks. To keep the startup scan fast, MacBroom skips it at launch time and shows `—` instead of a size. The actual scan runs the moment you open the Preview screen (`→`). While Preview loads, MacBroom totals the item sizes and writes them back to the module registry. When you press `←` to return to the Main screen, the real size and a proportional bar appear in place of `—` — and the module participates correctly in the overall size ranking.

**After cleaning:** Files are permanently deleted. This module targets personal files (videos, disk images, archives), not system caches.

> **Always use Preview (`→`) before cleaning this module.** These are your personal files, not system caches. Carefully review every item before deleting. The info bar will say `Files over 500 MB not accessed in 180+ days — size shown after opening Preview` as a reminder.

---

### 23. iOS Backups — `ios_backups` `[R]`

**What it cleans:** iPhone and iPad backup folders created by Finder (macOS Catalina and later) or iTunes, stored at:
- `~/Library/Application Support/MobileSync/Backup`

**After cleaning:** The backup is permanently deleted. MacBroom cannot recover it. Always make a fresh backup via Finder before running this module.

> **This is a Risky `[R]` module.** Open Preview to see each backup's name, date, and size before deciding.

---

### 24. Mail Attachments — `mail_attachments` `[M]`

**What it cleans:** Locally cached email attachments in `~/Library/Mail` that are older than `MB_MAIL_AGE_DAYS` days (default: 90 days).

**After cleaning:** The Mail app re-downloads attachments from the server the next time you open the relevant email. If the original email has been deleted from the server, the attachment may be unrecoverable.

---

### 25. AI Model Cache — `ai_models` `[R]`

**What it cleans:**
- Ollama model files (`~/.ollama/models`)
- LM Studio models (`~/Library/Application Support/LM Studio/models`)
- HuggingFace model cache (`~/.cache/huggingface`)
- PyTorch model cache (`~/.cache/torch`)

**After cleaning:** Model files are permanently deleted. They can be re-downloaded, but individual models range from hundreds of MB to tens of GB. Re-downloading can take a very long time on a slow connection.

> **This is a Risky `[R]` module.** Open Preview to see each model's name and size individually before deciding.

---

### 26. Trash — `trash` `[R]`

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

You can navigate and select files at this deeper level exactly as you would at the top level. Press `←` or `h` to go back up one level. Press `←` again to go back further, or all the way back to the Main screen.

**The rule for Enter in Preview:**
- Cursor on an **unchecked directory** → drill into it
- **Any items are checked** → delete everything that is checked (regardless of cursor position)

---

### Filter: search by name inside Preview

Press `/` in the Preview screen to enter filter mode. A search bar appears:

```
/ filter: chrome_
```

Type any part of a file or folder name. The list narrows in real time to show only matching items (case-insensitive). Scroll position and cursor reset to the top of the filtered list.

- `Backspace` — delete the last character of the filter
- `Esc` — clear the filter and exit filter mode
- While a filter is active, `A` and `N` only affect currently visible (filtered) items

---

### Deletion Log and Session History

MacBroom logs every file it deletes. Logs are stored at:

```
~/Library/Logs/MacBroom/operations.log   — every deletion with timestamp and size
~/Library/Logs/MacBroom/sessions/        — per-session records
~/Library/Logs/MacBroom/errors.log       — paths that failed and why
```

A session starts when you press `Enter` to begin cleaning and ends when all categories finish.

```bash
macbroom --log list        # List all recorded sessions with timestamps
macbroom --log last        # Show what was deleted in the most recent session
```

> **Important:** MacBroom uses `rm -rf` to permanently delete files. The deletion log is an audit trail only — files cannot be restored from it. Move anything you may need to your Desktop before cleaning.

---

### JSON Output

The `--json` flag produces machine-readable output for scripts and native app integrations:

```bash
macbroom scan --json         # Disk stats and sizes for all 26 categories
macbroom list browser --json # Individual items inside a specific category
```

Example scan output:

```json
{
  "disk": {"used_kb": 921600000, "total_kb": 994050048, "free_kb": 72450048},
  "modules": [
    {"id": "user_caches", "label": "User App Caches", "size_kb": 2150400},
    {"id": "browser", "label": "Browser Caches", "size_kb": 1331200}
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

The plist is installed at `~/Library/LaunchAgents/com.macbroom.cron.plist`. Scheduled runs use `--headless` mode (no TUI, no prompts). Risky `[R]` categories are never included in scheduled runs, regardless of the level setting.

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

| Command | Description |
| ------- | ----------- |
| `macbroom` | Open the interactive TUI |
| `macbroom --dry-run` | Open the TUI in Dry-Run mode |
| `macbroom scan` | Print a disk usage report for all 26 categories |
| `macbroom scan --json` | Same, as JSON |
| `macbroom list <module>` | List individual items inside a category |
| `macbroom list <module> --json` | Same, as JSON |
| `macbroom clean <module> [<module>...]` | Clean one or more specific categories |
| `macbroom clean --all` | Clean all categories including Risky |
| `macbroom clean --all --dry-run` | Preview what `--all` would delete |
| `macbroom --log list` | List all recorded deletion log sessions |
| `macbroom --log last` | Show what was deleted in the last session |
| `macbroom --install-cron [days] [level]` | Schedule automatic cleaning |
| `macbroom --remove-cron` | Remove the scheduled job |
| `macbroom --cron-status` | Show current schedule |
| `macbroom --headless --safe` | Silent clean, Safe categories only |
| `macbroom --headless --moderate` | Silent clean, Safe + Moderate categories |
| `macbroom --help` | Print usage reference |

**Valid module IDs for `list` and `clean`:**

```
user_caches       browser           dev_tools         system_logs
temp_files        node_cache        python_cache      jetbrains_cache
vscode_cache      flutter_cache     go_cache          rust_cache
ruby_cache        java_cache        docker_cache      android_cache
imessage_attachments  maintenance   memory_purge      app_leftovers
orphaned_files    large_old_files   ios_backups       mail_attachments
ai_models         trash
```

---

## Configuration

Set these environment variables in your `~/.zshrc` or `~/.bashrc` to customize behavior:

```bash
export MB_LOG_AGE_DAYS=14        # Delete logs older than 14 days (default: 7)
export MB_TEMP_AGE_DAYS=7        # Delete temp files older than 7 days (default: 3)
export MB_MAIL_AGE_DAYS=180      # Delete mail attachments older than 180 days (default: 90)
export MB_LOF_MIN_SIZE_MB=1000   # Large file threshold: 1 GB (default: 500 MB)
export MB_APP_LEFTOVERS_QUERY="" # App name to find in the App Leftovers module
```

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `MB_LOG_AGE_DAYS` | `7` | Minimum age in days for log files to be eligible for deletion |
| `MB_TEMP_AGE_DAYS` | `3` | Minimum age in days for temp files to be eligible for deletion |
| `MB_MAIL_AGE_DAYS` | `90` | Minimum age in days for Mail attachment caches to be eligible for deletion |
| `MB_LOF_MIN_SIZE_MB` | `500` | Minimum file size (MB) for the Large Old Files module |
| `MB_APP_LEFTOVERS_QUERY` | *(empty)* | If set, the App Leftovers module searches only for this app name |

---

## Safety and Security

MacBroom is designed so that even a bug in a module cannot delete system files or personal data. Multiple independent safeguards enforce this.

### Safeguard 1 — Path Allowlist

Every deletion goes through `mb_safe_rm()`, which checks the target path against a hard-coded list of permitted directory prefixes. If the path is not on the list, the deletion is refused, skipped, and logged to `errors.log`. No module can override this check.

Permitted prefixes include:

```
~/Library/Caches             ~/Library/Logs
~/Library/Application Support  ~/Library/Containers
~/Library/Group Containers   ~/Library/Preferences
~/Library/Saved Application State
~/Library/Messages/Attachments  ~/Library/Messages/StickerCache
~/Library/Application Support/MobileSync
~/Library/Mail
~/Library/Developer/Xcode/DerivedData
~/Library/Developer/CoreSimulator/Caches
~/.Trash   ~/.npm   ~/.gradle   ~/.cargo   ~/.pub-cache
~/.gem     ~/.dart  ~/.conda    ~/.pyenv   ~/.poetry
~/.android/cache  ~/.ollama  ~/.cache
~/go/pkg/mod/cache  ~/Library/Caches/go-build
~/Downloads  ~/Documents  ~/Desktop
~/Music  ~/Movies  ~/Pictures
/Library/Caches  /Library/Logs
/private/tmp  /private/var/tmp  /private/var/log
```

### Safeguard 2 — Protected Paths

Even within the allowlist, a second check blocks deletion of critical configuration:

| Path | What it protects |
| ---- | ---------------- |
| `~/.ssh` | SSH private keys |
| `~/.gnupg` | GPG encryption keys |
| `~/.aws` | AWS credentials |
| `~/.kube` | Kubernetes configuration |
| `~/.gitconfig` | Git global configuration |
| `~/.zshrc` | Zsh shell configuration |
| `~/.bashrc` | Bash shell configuration |
| `~/.profile` | Login shell configuration |
| `~/.local/share` | XDG local application data |

### Safeguard 3 — Risky Categories Excluded from Bulk Actions

Categories rated `[R]` (Trash, iMessage Attachments, iOS Backups, AI Models) are excluded from:
- The `A` key on the Main screen
- `macbroom clean --all`
- All scheduled/headless cleaning

They must be selected manually, every single time, with no shortcuts.

### Safeguard 4 — Full Deletion Log

Every deletion is written to `~/Library/Logs/MacBroom/operations.log` with a timestamp, the full path, and the size freed. Every failed deletion is written to `errors.log`.

### Safeguard 5 — Zero Network Access

MacBroom makes no network connections. There is no telemetry, no update checks, no analytics, and no data collection of any kind.

### Safeguard 6 — Dry-Run Mode

Press `D` or use `--dry-run` to simulate any operation. All file listings and sizes are real; all deletions are suppressed.

---

## Why the Disk Bar Doesn't Change Immediately

After cleaning, the disk bar in MacBroom (and in Finder / About This Mac) often does not immediately show a smaller number — even though the Done screen reported several gigabytes freed. This is not a bug.

**The reason:** macOS uses APFS (Apple File System), which has a concept called *purgeable space*. When a file is deleted, the blocks it occupied are not immediately returned to the free pool. Instead, they are marked as *purgeable* — space that macOS can reclaim when another app needs room. The actual reclaim happens in the background, triggered by memory pressure or a manual `purge` command.

This is the same reason that "Optimized Storage" in macOS can report more free space than `df` shows — purgeable space is treated differently by different tools.

**What the numbers mean:**
- **Total Freed** on the Done screen = the accurate total of what was deleted from disk
- **Disk bar** = what macOS has physically reclaimed so far (may lag)
- **APFS Purgeable** on the Main screen = space macOS is holding as reclaimable

Disk stats in Finder typically update within minutes to an hour after a large clean. Pressing any key on the Done screen rescans and refreshes MacBroom's own disk bar.

---

## Project Structure

```
MacBroom/
├── macbroom                      # Main script: CLI router, module registry, TUI event loop
├── install.sh                    # Installer / uninstaller
├── lib/
│   ├── core.sh                   # Logging, mb_safe_rm, path allowlist, size formatting
│   ├── disk.sh                   # APFS disk stats: mb_disk_used_kb, mb_disk_total_kb
│   ├── ui.sh                     # All five TUI screens, key reader, spinner
│   ├── undo.sh                   # Session recording and deletion log
│   └── cron.sh                   # launchd plist management
└── modules/                      # One file per cleaning category (26 total)
    ├── user_caches.sh
    ├── browser.sh
    ├── dev_tools.sh
    └── ...
```

### Module API

Each module file implements up to four Bash functions:

```bash
# Required — print total reclaimable size in KB to stdout
<name>_scan()

# Required — print lines of "size_kb|label|path", sorted largest first
<name>_list()

# Required — clean; accept (dry_run, result_file), write freed KB to result_file
<name>_clean()

# Optional — print a command name; module is skipped if the command is not in PATH
<name>_requires()
```

To add a module: create `modules/<name>.sh` with these functions, `source` it in `macbroom`, and add an entry to each of the registry arrays:

| Array | Purpose |
| ----- | ------- |
| `MB_MOD_NAMES` | Internal ID used by CLI commands |
| `MB_MOD_LABELS` | Display name shown in the TUI |
| `MB_MOD_DESCS` | One-line description shown in the info bar |
| `MB_MOD_SAFETY` | `safe`, `moderate`, or `risky` |
| `MB_MOD_SCAN_FNS` | Reference to the `_scan` function |
| `MB_MOD_LIST_FNS` | Reference to the `_list` function |
| `MB_MOD_CLEAN_FNS` | Reference to the `_clean` function |
| `MB_MOD_DEFERRED` | `1` to skip at startup and scan lazily when Preview opens; `0` to scan immediately |

---

## Troubleshooting

**Large Old Files shows `—` instead of a size**

This is expected. The module scans your entire home folder with `find`, which takes too long to run at startup alongside 25 other scans. Press `→` to open its Preview screen — the scan runs immediately while the spinner plays. When you press `←` to return, the real size replaces `—` and the size bar appears. No manual rescan needed.

**A module shows 0 bytes**

The tool required by that module is not installed or not running:
- Docker module: Docker Desktop must be installed and the Docker daemon must be running
- Go module: requires `go` in your PATH
- Flutter/Dart: requires `flutter` in your PATH
- Modules skip themselves automatically when their requirement is absent — this is expected behavior

**The TUI looks garbled or misaligned**

- Resize your terminal window — MacBroom redraws the entire interface on every resize
- Confirm your terminal's character encoding is set to UTF-8
- Confirmed working: macOS Terminal.app, iTerm2, Ghostty, Warp, Alacritty

**Some paths are skipped even though they exist**

MacBroom only deletes paths that match its hard-coded allowlist. If a module finds files in a path that is not on the list, those files are skipped and logged to `~/Library/Logs/MacBroom/errors.log`. Grant Full Disk Access to your terminal app if you see permission-related skips.

**Cleaning requires Full Disk Access**

Folders like `~/Library/Containers`, `~/Library/Mail`, and `~/Library/Messages` are protected by macOS and require Full Disk Access to read and modify:

`System Settings → Privacy & Security → Full Disk Access → add your terminal app`

**Permission denied on `/private/tmp`**

Files in `/private/tmp` owned by the system or other users are skipped. MacBroom does not use `sudo` for temp file cleanup. Your own temp files are cleaned; system-owned ones are left alone.

**Terminal closes with "Saving session... [Process completed]"**

This is macOS Terminal.app showing zsh's normal logout message when the process exits. It is not a crash or an error. It means MacBroom exited cleanly (e.g., you pressed `Q`). If this appears when you did not press `Q`, open MacBroom from iTerm2 or Ghostty — those terminals keep the window open after exit so you can read any error messages.

**Disk bar does not update after cleaning**

Expected behavior on APFS. See [Why the Disk Bar Doesn't Change Immediately](#why-the-disk-bar-doesnt-change-immediately). The Total Freed counter is accurate; the disk bar reflects what macOS has physically reclaimed so far.

---

## License

MIT License. Copyright (c) 2026 AarontheGalaxy.

---

*MacBroom — built for macOS power users who want fast, transparent, and safe disk cleanup without black-box GUIs or third-party runtimes.*
