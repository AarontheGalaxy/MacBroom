#!/usr/bin/env bash
# MacBroom – TUI engine: simplified minimalist style for maximum resize stability.

[[ -n "${MB_UI_LOADED:-}" ]] && return 0
readonly MB_UI_LOADED=1

# ── Symbols ────────────────────────────────────────────────────
readonly _S_ARROW='▶' _S_CHECK='✓' _S_DOT='·'

# Spinner frames
readonly -a _SPIN=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
_SPIN_IDX=0

mb_spin_next() {
    _SPIN_IDX=$(( (_SPIN_IDX + 1) % 10 ))
    printf '%s' "${_SPIN[$_SPIN_IDX]}"
}

# ── Terminal helpers ───────────────────────────────────────────
_MB_COLS=80
_MB_ROWS=24

mb_update_term_size() {
    _MB_COLS=$(tput cols  2>/dev/null || echo 80)
    _MB_ROWS=$(tput lines 2>/dev/null || echo 24)
}

mb_goto()       { tput cup "$(( $2 - 1 ))" "$(( $1 - 1 ))" 2>/dev/null; }
mb_clear_line() { tput el  2>/dev/null; }
mb_clrscr()     { tput clear 2>/dev/null || printf '\033[2J\033[H'; }

# ── Drawing primitives ─────────────────────────────────────────
_rep() {
    local char="$1" n="$2" out="" i
    for (( i=0; i<n; i++ )); do out+="$char"; done
    printf '%s' "$out"
}

# Minimalist horizontal line
_draw_hr() {
    local row="$1"
    mb_goto 1 "$row"
    printf "${C_DIM}%s${C_NC}" "$(_rep '─' "$_MB_COLS")"
}

# Simple row with clear-to-EOL
_draw_row_simple() {
    local col="$1" row="$2" text="$3"
    mb_goto "$col" "$row"
    printf '%s' "$text"
    tput el 2>/dev/null || true
}

# ── Size bar ───────────────────────────────────────────────────
mb_size_bar() {
    local pct="${1:-0}" w="${2:-16}"
    local filled=$(( pct * w / 100 ))
    if [[ $filled -gt $w ]]; then filled=$w; fi
    local empty=$(( w - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+='■'; done
    for (( i=0; i<empty;  i++ )); do bar+='□'; done
    if   (( pct >= 70 )); then printf "${C_RED}%s${C_NC}"    "$bar"
    elif (( pct >= 35 )); then printf "${C_YELLOW}%s${C_NC}" "$bar"
    else                       printf "${C_GREEN}%s${C_NC}"  "$bar"
    fi
    return 0
}

# ── Key reader ─────────────────────────────────────────────────
# Reads into global MB_LAST_KEY to avoid running read inside a $() subshell,
# which can break terminal raw-mode input on macOS bash 3.2.
# Handles both ANSI cursor keys (\x1b[B) and application cursor keys (\x1bOB).
MB_LAST_KEY=""
_MB_STTY_SAVE=""

mb_read_key() {
    MB_LAST_KEY=""
    local _k _c1 _c2
    # -s suppresses bash-level echo
    if ! IFS= read -r -s -n1 _k 2>/dev/null; then
        # EOF or read failure
        MB_LAST_KEY="EOF"
        return 0
    fi

    # If _k is empty, it means read encountered the delimiter (Enter)
    if [[ -z "$_k" ]]; then
        MB_LAST_KEY=$'\n'
        return 0
    fi

    if [[ "$_k" == $'\x1b' ]]; then
        # bash 3.2 (default on macOS) truncates fractional timeouts to 0,
        # making read -t 0.15 return immediately with no data.
        # Use integer timeout (1) so the rest of the escape sequence is read.
        IFS= read -r -s -n1 -t 1 _c1 2>/dev/null || true
        _k+="$_c1"
        if [[ "$_c1" == '[' || "$_c1" == 'O' ]]; then
            IFS= read -r -s -n1 -t 1 _c2 2>/dev/null || true
            _k+="$_c2"
        fi
    fi
    MB_LAST_KEY="$_k"
    return 0
}

# Drain any stale bytes left in the terminal input buffer.
mb_drain_input() {
    local _d=0
    while read -t 0 2>/dev/null; do
        IFS= read -r -s -n1 _ 2>/dev/null || break
        _d=$(( _d + 1 ))
        if (( _d > 64 )); then break; fi
    done
    return 0
}

# ── TUI state ──────────────────────────────────────────────────
MB_TUI_STATE="SCANNING"
MB_CURSOR=0
MB_SCROLL=0
_MB_LIST_ROWS=15
MB_PREVIEW_MOD=""
MB_PREVIEW_ITEMS=()
MB_PREVIEW_SELECTED=()
MB_PREVIEW_CURSOR=0
MB_PREVIEW_SCROLL=0
MB_PREVIEW_LOADING=false
MB_PREVIEW_FILTER=""
MB_PREVIEW_FILTER_MODE=false
MB_PREVIEW_DRILL_STACK=()
MB_PREVIEW_DRILL_DEPTH=0

MB_CLEAN_STATUS=()
MB_CLEAN_FREED=()
MB_CLEAN_TOTAL=0

# ── Cleanup ────────────────────────────────────────────────────
mb_tui_cleanup() {
    trap - WINCH 2>/dev/null || true
    tput rmcup  2>/dev/null || true
    tput cnorm  2>/dev/null || true
    # Restore terminal settings saved at TUI startup
    if [[ -n "$_MB_STTY_SAVE" ]]; then
        stty "$_MB_STTY_SAVE" 2>/dev/null || true
    fi
    printf '\n'
}

# ── RENDER: SCANNING ──────────────────────────────────────────
_render_scanning() {
    local msg="${1:-Scanning your Mac...}"
    mb_update_term_size
    mb_clrscr
    local mid=$(( _MB_ROWS / 2 ))
    
    mb_goto 1 2
    printf "  ${C_BOLD}MacBroom${C_NC}"
    _draw_hr 3
    
    mb_goto 4 "$mid"
    printf "  ${C_CYAN}⠋${C_NC}  ${C_BOLD}${msg}${C_NC}"
    
    mb_goto 1 $(( _MB_ROWS - 1 ))
    _draw_hr $(( _MB_ROWS - 1 ))
    mb_goto 3 $(( _MB_ROWS ))
    printf "${C_DIM}Please wait while we analyze your system...${C_NC}"
}

# ── RENDER: MAIN ──────────────────────────────────────────────
_render_main() {
    mb_update_term_size
    local row i s
    printf '\033[H'   # cursor home without clearing — no flash

    mb_goto 1 1; tput el 2>/dev/null || true   # clear unused row 1

    # Header
    local title="MacBroom"
    if [[ "${MB_DRY_RUN:-false}" == "true" ]]; then title="MacBroom (DRY RUN)"; fi
    mb_goto 1 2
    printf "  ${C_BOLD}${title}${C_NC}"
    tput el 2>/dev/null || true
    _draw_hr 3
    row=4

    # Disk bar
    local disk_pct=0
    if (( ${MB_DISK_TOTAL_KB:-0} > 0 )); then
        disk_pct=$(( MB_DISK_USED_KB * 100 / MB_DISK_TOTAL_KB ))
    fi
    local disk_bar; disk_bar=$(mb_size_bar "$disk_pct" 16)
    local used_h total_h
    used_h=$(mb_format_kb "${MB_DISK_USED_KB:-0}")
    total_h=$(mb_format_kb "${MB_DISK_TOTAL_KB:-0}")
    _draw_row_simple 3 $row "Disk Usage: ${disk_bar}  ${C_BOLD}${used_h}${C_NC} / ${total_h} (${disk_pct}%)"
    row=$(( row + 1 ))

    if [[ -n "${_MB_APFS_PURGEABLE:-}" ]]; then
        _draw_row_simple 3 $row "${C_DIM}APFS Purgeable: ${C_YELLOW}${_MB_APFS_PURGEABLE}${C_NC}${C_NC}"
        row=$(( row + 1 ))
    fi

    _draw_hr "$row"
    row=$(( row + 1 ))

    # ── Module list ────────────────────────────────────────────
    # Reserve 3 rows at bottom: info bar + HR + footer
    _MB_LIST_ROWS=$(( _MB_ROWS - row - 3 ))
    if [[ $_MB_LIST_ROWS -lt 3 ]]; then _MB_LIST_ROWS=3; fi

    local max_kb=1
    for (( i=0; i<${#MB_MOD_SIZES_KB[@]}; i++ )); do
        s="${MB_MOD_SIZES_KB[$i]:-0}"
        if (( s > max_kb )); then max_kb=$s; fi
    done

    local total_mods="${#MB_MOD_NAMES[@]}"
    local max_scroll=$(( total_mods - _MB_LIST_ROWS ))
    if [[ $max_scroll -lt 0 ]]; then max_scroll=0; fi
    if (( MB_SCROLL > max_scroll )); then MB_SCROLL=$max_scroll; fi
    if (( MB_SCROLL < 0 )); then MB_SCROLL=0; fi

    for (( i=MB_SCROLL; i<total_mods; i++ )); do
        if (( row >= _MB_ROWS - 2 )); then break; fi

        local label="${MB_MOD_LABELS[$i]}"
        local size_kb="${MB_MOD_SIZES_KB[$i]:-0}"
        local sel="${MB_MOD_SELECTED[$i]:-0}"
        local safety="${MB_MOD_SAFETY[$i]:-safe}"

        local cursor_str="  "
        if [[ "$i" -eq "$MB_CURSOR" ]]; then cursor_str="${C_CYAN}▶ ${C_NC}"; fi
        local chk_str="${C_DIM}○${C_NC} "
        if [[ "$sel" -eq 1 ]]; then chk_str="${C_GREEN}●${C_NC} "; fi
        local safety_badge="${C_DIM}[S]${C_NC}"
        if [[ "$safety" == "moderate" ]]; then safety_badge="${C_YELLOW}[M]${C_NC}"; fi
        if [[ "$safety" == "risky" ]];    then safety_badge="${C_RED}[R]${C_NC}"; fi

        # Visible prefix = 2 (cursor) + 2 (chk) + 3 (badge) + 1 (space) + len(label) = 8+len
        # Visible suffix = 10 (bar) + 2 (spaces) + 9 (size field) = 21
        local pad=$(( _MB_COLS - 8 - ${#label} - 21 ))
        if [[ $pad -lt 1 ]]; then pad=1; fi
        local dots="${C_DIM}$(_rep '·' $pad)${C_NC}"

        if [[ "${MB_MOD_DEFERRED[$i]:-0}" -eq 1 && "$size_kb" -eq 0 ]]; then
            # Deferred module: not scanned at startup — show placeholder
            _draw_row_simple 1 "$row" \
                "${cursor_str}${chk_str}${safety_badge} ${label}${dots}${C_DIM}          $(printf '%9s' '—')${C_NC}"
        else
            local pct=0
            if (( max_kb > 0 )); then pct=$(( size_kb * 100 / max_kb )); fi
            local sbar; sbar=$(mb_size_bar "$pct" 10)

            # Size field color: green when selected, bold when cursor is on this row
            local size_str; size_str=$(printf '%9s' "$(mb_format_kb "$size_kb")")
            local size_colored
            if   [[ "$i" -eq "$MB_CURSOR" && "$sel" -eq 1 ]]; then size_colored="${C_GREEN}${C_BOLD}${size_str}${C_NC}"
            elif [[ "$sel" -eq 1 ]];                               then size_colored="${C_GREEN}${size_str}${C_NC}"
            elif [[ "$i" -eq "$MB_CURSOR" ]];                      then size_colored="${C_BOLD}${size_str}${C_NC}"
            else                                                        size_colored="${C_DIM}${size_str}${C_NC}"
            fi

            _draw_row_simple 1 "$row" \
                "${cursor_str}${chk_str}${safety_badge} ${label}${dots}${sbar}  ${size_colored}"
        fi
        row=$(( row + 1 ))
    done

    # Clear stale rows left over from a previous longer list or resize
    while (( row < _MB_ROWS - 2 )); do
        mb_goto 1 "$row"; tput el 2>/dev/null || true
        row=$(( row + 1 ))
    done

    # ── Info bar: safety badge + description + scroll position ──
    local _safety_cur="${MB_MOD_SAFETY[$MB_CURSOR]:-safe}"
    local _sbadge="" _sbadge_vis=""
    case "$_safety_cur" in
        safe)     _sbadge="${C_GREEN}[S]${C_NC}${C_DIM} Safe  · ";     _sbadge_vis="[S] Safe  · "     ;;
        moderate) _sbadge="${C_YELLOW}[M]${C_NC}${C_DIM} Moderate  · "; _sbadge_vis="[M] Moderate  · " ;;
        risky)    _sbadge="${C_RED}[R]${C_NC}${C_DIM} Risky  · ";      _sbadge_vis="[R] Risky  · "    ;;
    esac
    local desc="${MB_MOD_DESCS[$MB_CURSOR]:-}"
    local scroll_sfx=""
    if (( total_mods > _MB_LIST_ROWS )); then
        local vis_end=$(( MB_SCROLL + _MB_LIST_ROWS ))
        if (( vis_end > total_mods )); then vis_end=$total_mods; fi
        scroll_sfx=" ($(( MB_SCROLL + 1 ))-${vis_end}/${total_mods})"
    fi
    local max_desc=$(( _MB_COLS - ${#scroll_sfx} - ${#_sbadge_vis} - 3 ))
    if (( ${#desc} > max_desc && max_desc > 1 )); then desc="${desc:0:$(( max_desc - 1 ))}…"; fi
    mb_goto 1 $(( _MB_ROWS - 2 ))
    printf "  ${C_DIM}${_sbadge}${desc}${scroll_sfx}${C_NC}"
    tput el 2>/dev/null || true

    # ── Footer ─────────────────────────────────────────────────
    _draw_hr $(( _MB_ROWS - 1 ))
    mb_goto 1 $(( _MB_ROWS ))
    printf " ${C_DIM}↑↓ Navigate  Space Toggle  → Preview  Enter Clean  A All  N None  Q Quit${C_NC}"
    tput el 2>/dev/null || true
}

# Global so the event loop can compute scroll bounds matching the render.
_MB_PREVIEW_LIST_ROWS=10

# ── RENDER: PREVIEW ────────────────────────────────────────────
_render_preview() {
    mb_update_term_size
    local row i
    printf '\033[H'   # cursor home without clearing — no flash

    mb_goto 1 1; tput el 2>/dev/null || true

    local idx=0
    for (( i=0; i<${#MB_MOD_NAMES[@]}; i++ )); do
        if [[ "${MB_MOD_NAMES[$i]}" == "$MB_PREVIEW_MOD" ]]; then idx=$i; break; fi
    done
    local label="${MB_MOD_LABELS[$idx]}"
    local safety="${MB_MOD_SAFETY[$idx]:-safe}"

    mb_goto 1 2
    printf "  ${C_BOLD}MacBroom${C_NC}  ${C_DIM}›  ${label}${C_NC}"
    tput el 2>/dev/null || true
    _draw_hr 3
    row=4

    # ── Module description ──────────────────────────────────────
    local desc="${MB_MOD_DESCS[$idx]:-}"
    if [[ -n "$desc" ]]; then
        local max_d=$(( _MB_COLS - 4 ))
        if (( ${#desc} > max_d && max_d > 1 )); then desc="${desc:0:$(( max_d - 1 ))}…"; fi
        _draw_row_simple 3 $row "${C_DIM}${desc}${C_NC}"
        row=$(( row + 1 ))
    fi

    # ── Effect / consequence ────────────────────────────────────
    local effect="${MB_MOD_EFFECTS[$idx]:-}"
    if [[ -n "$effect" ]]; then
        local sc="${C_GREEN}" ss="✓ Safe:"
        if [[ "$safety" == "moderate" ]]; then sc="${C_YELLOW}"; ss="! Note:"; fi
        if [[ "$safety" == "risky" ]];    then sc="${C_RED}";    ss="⚠ Warning:"; fi
        _draw_row_simple 3 $row "${sc}${ss}${C_NC} ${C_DIM}${effect}${C_NC}"
        row=$(( row + 1 ))
    fi

    _draw_hr "$row"
    row=$(( row + 1 ))

    # ── Drill breadcrumb / filter ───────────────────────────────
    if (( MB_PREVIEW_DRILL_DEPTH > 0 )); then
        local crumb="Path: /"
        local dp
        for (( dp=0; dp<${#MB_PREVIEW_DRILL_STACK[@]}; dp++ )); do
            crumb+="$(basename "${MB_PREVIEW_DRILL_STACK[$dp]}")/"
        done
        _draw_row_simple 3 $row "${C_DIM}${crumb}${C_NC}"
        row=$(( row + 1 ))
    fi
    if [[ -n "$MB_PREVIEW_FILTER" ]]; then
        _draw_row_simple 3 $row "${C_YELLOW}/ filter:${C_NC} ${MB_PREVIEW_FILTER}_"
        row=$(( row + 1 ))
    fi

    # ── Item list ───────────────────────────────────────────────
    local list_rows=$(( _MB_ROWS - row - 2 ))
    if [[ $list_rows -lt 1 ]]; then list_rows=1; fi
    _MB_PREVIEW_LIST_ROWS=$list_rows

    if [[ "$MB_PREVIEW_LOADING" == "true" ]]; then
        _draw_row_simple 3 $row "  ${C_CYAN}⠋${C_NC}  Loading items..."
        row=$(( row + 1 ))
    elif [[ ${#MB_PREVIEW_ITEMS[@]} -eq 0 ]]; then
        _draw_row_simple 3 $row "  ${C_DIM}(nothing found)${C_NC}"
        row=$(( row + 1 ))
    else
        local filtered_items=() filtered_indices=()
        for (( i=0; i<${#MB_PREVIEW_ITEMS[@]}; i++ )); do
            local item="${MB_PREVIEW_ITEMS[$i]}"
            local rest="${item#*|}"
            local slabel="${rest%%|*}"
            if [[ -z "$MB_PREVIEW_FILTER" ]] || [[ "${slabel,,}" == *"${MB_PREVIEW_FILTER,,}"* ]]; then
                filtered_items+=("$item")
                filtered_indices+=("$i")
            fi
        done

        local visible=${#filtered_items[@]}
        local end=$(( MB_PREVIEW_SCROLL + list_rows ))
        if [[ $end -gt $visible ]]; then end=$visible; fi

        local j
        for (( j=MB_PREVIEW_SCROLL; j<end; j++ )); do
            local item="${filtered_items[$j]}"
            local real_j="${filtered_indices[$j]}"
            local sk="${item%%|*}"
            local rest="${item#*|}"
            local slabel="${rest%%|*}"

            local cursor_str="  "
            if [[ "$j" -eq "$MB_PREVIEW_CURSOR" ]]; then cursor_str="${C_CYAN}▶ ${C_NC}"; fi
            local chk_str="${C_DIM}[ ]${C_NC} "
            if [[ "${MB_PREVIEW_SELECTED[$real_j]:-0}" -eq 1 ]]; then chk_str="${C_GREEN}[✓]${C_NC} "; fi

            # Visible prefix = 2 (cursor) + 4 ("[ ] " or "[✓] ") + len(slabel)
            # Visible suffix = 9 (size field) + 2 (gap) = 11; but original used 9 alone
            local pad=$(( _MB_COLS - 6 - ${#slabel} - 9 ))
            if [[ $pad -lt 1 ]]; then pad=1; fi
            _draw_row_simple 1 "$row" \
                "${cursor_str}${chk_str}${slabel}$(_rep ' ' $pad)$(printf '%9s' "$(mb_format_kb "$sk")")"
            row=$(( row + 1 ))
        done
    fi

    # Clear stale rows between list end and footer
    while (( row < _MB_ROWS - 1 )); do
        mb_goto 1 "$row"; tput el 2>/dev/null || true
        row=$(( row + 1 ))
    done

    # ── Footer ─────────────────────────────────────────────────
    _draw_hr $(( _MB_ROWS - 1 ))
    mb_goto 1 $(( _MB_ROWS ))
    local _sel_count=0
    local _si
    for (( _si=0; _si<${#MB_PREVIEW_SELECTED[@]}; _si++ )); do
        [[ "${MB_PREVIEW_SELECTED[$_si]:-0}" -eq 1 ]] && _sel_count=$(( _sel_count + 1 ))
    done
    if [[ "$_sel_count" -eq 0 ]]; then
        printf " ${C_DIM}← Back  ↑↓ Navigate  ${C_YELLOW}Space${C_NC}${C_DIM} to select files — nothing deleted until you select  Q Quit${C_NC}"
    else
        printf " ${C_DIM}← Back  ↑↓ Navigate  Space Toggle  / Filter  ${C_GREEN}Enter${C_NC}${C_DIM} Delete ${_sel_count} selected  Q Quit${C_NC}"
    fi
    tput el 2>/dev/null || true
}

# ── RENDER: CLEANING ──────────────────────────────────────────
_render_cleaning() {
    mb_update_term_size
    mb_clrscr
    mb_goto 1 2
    printf "  ${C_BOLD}MacBroom${C_NC}  ${C_DIM}›  Cleaning...${C_NC}"
    _draw_hr 3
    local row=4

    local done_count=0 selected_count=0
    for (( i=0; i<${#MB_MOD_NAMES[@]}; i++ )); do
        local st="${MB_CLEAN_STATUS[$i]:-waiting}"
        local label="${MB_MOD_LABELS[$i]}"
        local freed="${MB_CLEAN_FREED[$i]:-0}"

        if [[ "${MB_MOD_SELECTED[$i]:-0}" -eq 1 ]]; then
            selected_count=$(( selected_count + 1 ))
        fi

        case "$st" in
            waiting)  _draw_row_simple 3 $row "  ${C_DIM}○  ${label}${C_NC}" ;;
            cleaning) _draw_row_simple 3 $row "  ${C_CYAN}⠋${C_NC}  ${label} ${C_DIM}(cleaning...)${C_NC}" ;;
            done)
                _draw_row_simple 3 $row "  ${C_GREEN}✓${C_NC}  ${C_BOLD}${label}${C_NC} ${C_DIM}(freed $(mb_format_kb "$freed"))${C_NC}"
                done_count=$(( done_count + 1 ))
                ;;
            skipped)  continue ;;
        esac
        row=$(( row + 1 ))
        if (( row >= _MB_ROWS - 2 )); then break; fi
    done

    mb_goto 1 $(( _MB_ROWS - 1 ))
    _draw_hr $(( _MB_ROWS - 1 ))
    mb_goto 3 $(( _MB_ROWS ))
    local prog_pct=0
    if (( selected_count > 0 )); then prog_pct=$(( done_count * 100 / selected_count )); fi
    printf "Progress: $(mb_size_bar "$prog_pct" 20) ${done_count}/${selected_count}"
}

# ── RENDER: DONE ──────────────────────────────────────────────
_render_done() {
    mb_update_term_size
    mb_clrscr
    mb_goto 1 2
    printf "  ${C_BOLD}MacBroom${C_NC}  ${C_DIM}›  Done!${C_NC}"
    _draw_hr 3
    local row=4

    for (( i=0; i<${#MB_MOD_NAMES[@]}; i++ )); do
        [[ "${MB_CLEAN_STATUS[$i]:-}" == "done" ]] || continue
        _draw_row_simple 3 $row "  ${C_GREEN}✓${C_NC}  ${MB_MOD_LABELS[$i]} ${C_DIM}($(mb_format_kb "${MB_CLEAN_FREED[$i]:-0}"))${C_NC}"
        row=$(( row + 1 ))
        if (( row >= _MB_ROWS - 4 )); then break; fi
    done

    local total_h; total_h=$(mb_format_kb "$MB_CLEAN_TOTAL")
    _draw_row_simple 3 $(( _MB_ROWS - 3 )) "${C_BOLD}Total Freed: ${C_GREEN}${total_h}${C_NC}"
    _draw_row_simple 3 $(( _MB_ROWS - 2 )) "${C_DIM}Note: Disk bar updates after macOS reclaims APFS purgeable space.${C_NC}"

    _draw_hr $(( _MB_ROWS - 1 ))
    mb_goto 3 $(( _MB_ROWS ))
    printf "${C_DIM}Press any key to rescan and return to main menu  Q to quit${C_NC}"
}

_MB_LAST_STATE=""
mb_tui_render() {
    # On state transitions, do a full clear once so stale content from the
    # previous screen doesn't bleed through the home-without-clear renders.
    if [[ "$MB_TUI_STATE" != "$_MB_LAST_STATE" ]]; then
        mb_clrscr
        _MB_LAST_STATE="$MB_TUI_STATE"
    fi
    case "$MB_TUI_STATE" in
        SCANNING) _render_scanning "${1:-}" ;;
        MAIN)     _render_main ;;
        PREVIEW)  _render_preview ;;
        CLEANING) _render_cleaning ;;
        DONE)     _render_done ;;
    esac
}

mb_tui_on_resize() {
    mb_update_term_size
    # Redraw current state
    mb_tui_render
}
