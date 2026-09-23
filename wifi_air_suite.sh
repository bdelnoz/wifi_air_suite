#!/usr/bin/env bash
# ==============================================================================
# PATH         : ./wifi_air_suite.sh
# SCRIPT NAME  : wifi_air_suite.sh
# AUTHOR       : Bruno DELNOZ
# EMAIL        : bruno.delnoz@protonmail.com
# TARGET USAGE : Wi-Fi RXH / Package scan WIFI
# VERSION      : v3.0.0
# DATE         : 2026-09-23 23:37
# ==============================================================================
#
# CLI / TASK CONTRACT PRINCIPLE
# ---------------------
# One explicit execution gate:
#
#   --exec
#
# One explicit action:
#
#   --capture
#   --check
#   --crack
#   --attack-hosts
#   --attack-preauth
#   --test-injection
#
# Informational / maintenance actions do not require --exec:
#
#   --prereq
#   --check-prereq
#   --doctor
#   --init
#   --show-paths
#   --print-config
#   --list-captures
#   --list-csv
#   --clean-tmp
#   --clean-runtime
#   --update-oui
#   --version
#   --help
#   --changelog
#
# Responsibilities are separated:
#
#   --capture        = airodump-ng only, never aircrack-ng
#   --check          = inspect capture / handshake inventory
#   --crack          = aircrack-ng, explicit wordlist only
#   --attack-hosts   = deauth selected AP/station pairs from CSV
#   --attack-preauth = fakeauth selected AP/station pairs from CSV
#   --test-injection = aireplay-ng injection test
#
# Runtime layout:
#
#   ./wifi_air_suite.sh
#   ./myinfo/
#   ./.results/
#
# ==============================================================================
# CHANGELOG
# ==============================================================================
# v3.0.0 - 2026-09-23 23:37 - Bruno DELNOZ
#   MAJOR:
#   - Establishes a clean v3 baseline from the validated v2.1.4 implementation.
#   - Consolidates the complete documentation set and Product Guide for the
#     current CLI, runtime layout, capture workflow, OUI maintenance and
#     targeted BSSID/channel capture.
#   PRESERVED:
#   - No hidden behavioral rewrite: v2.1.4 operational semantics are preserved.
#   - --channel N remains capture-only, requires --bssid, and replaces the
#     default multi-channel list only when explicitly supplied.
#   - --nolog, --update-oui, interval capture, post-processing, Kate integration,
#     exclusions, check/crack separation and authorized/lab action gates remain.
#
# v2.1.4 - 2026-09-23 23:37 - Bruno DELNOZ
#   ADDED:
#   - --channel N for targeted CAPTURE of a specific BSSID on one Wi-Fi channel.
#   - --channel is validated against the channel set already supported by the
#     capture engine and requires both --capture and --bssid.
#   CHANGED:
#   - When --channel is supplied, airodump-ng receives only that channel instead
#     of the default multi-channel list. Without --channel, behavior is unchanged.
#   PRESERVED:
#   - --nolog, --post-process, interval capture, OUI update and all existing
#     capture/check/crack/action semantics remain unchanged.
#
# v2.1.3 - 2026-09-23 08:10 - Bruno DELNOZ
#   ADDED:
#   - --update-oui refreshes myinfo/oui.txt from the IEEE Registration Authority
#     public MA-L/OUI listing.
#   - The update is downloaded to runtime tmp storage, validated, normalized to
#     AA:BB:CC<TAB>Manufacturer format, then atomically installed.
#   - Existing myinfo/oui.txt is copied to myinfo/oui.txt.bak before replacement.
#   - curl is preferred for download; wget is accepted as a fallback.
#   - WIFI_AIR_SUITE_OUI_URL can override the source URL for testing/mirrors.
#   PRESERVED:
#   - Failed downloads/validation never overwrite the current OUI database.
#   - --nolog behavior and all v2.1.2 capture/action behavior are unchanged.
#
# v2.1.2 - 2026-09-22 00:31 - Bruno DELNOZ
#   ADDED:
#   - --nolog (alias --no-log) disables persistent runtime log files.
#   - In CAPTURE live mode, --nolog runs airodump-ng directly on the current
#     terminal instead of the util-linux script PTY logger, preserving the live
#     table without creating airodump-*.log files.
#   - In spinner and authorized/lab action modes, log sinks are redirected to
#     /dev/null while terminal output remains available where applicable.
#   CHANGED:
#   - setup_logs() no longer creates GLOBAL/ACTION/AIRODUMP log files when
#     --nolog is active.
#   - post-process keeps CAP/CSV/filtered/enriched/generated outputs unchanged
#     and simply has no global log file to copy when --nolog is active.
#   PRESERVED:
#   - Default behavior without --nolog remains unchanged.
#   - Capture/check/crack/action separation, interval capture, --post-process,
#     --open-kate, --accept, runtime layout and monitor handling are preserved.
#
# v2.1.1 - 2026-09-16 03:05 - Bruno DELNOZ
#   CHANGED:
#   - set_unset_to_monitor.sh is now resolved from the same directory as
#     wifi_air_suite.sh instead of PROJECT_ROOT/tools/monitor/.
#   - PROJECT_ROOT now equals BASE_DIR because the public repository root is the
#     directory that contains wifi_air_suite.sh and set_unset_to_monitor.sh.
#   PRESERVED:
#   - v2.1.0 filtered Markdown generation, --open-kate, interval capture,
#     --post-process, --accept, runtime layout and all business actions.
#
# v2.1.0 - 2026-09-16 02:57 - Bruno DELNOZ
#   ADDED:
#   - Generates a Markdown equivalent of each filtered CSV during --post-process.
#     The file is stored beside the CSV as *.filtered.md in .results/filtered/.
#   - --open-kate opens each newly generated filtered Markdown file in Kate.
#     Kate is started asynchronously so capture intervals continue immediately.
#   - The filtered Markdown contains separate Access Points and Stations / Clients
#     tables generated from the already-filtered CSV; filtering logic is not duplicated.
#   CHANGED:
#   - Generated filtered Markdown files are also copied to .results/generated/.
#   - --open-kate requires --post-process and is valid only with --capture.
#   PRESERVED:
#   - Existing filtered CSV, enriched CSV, CAP/CSV naming, interval behavior,
#     --accept semantics, directories and behavior without --open-kate.
#
# v2.0.0 - 2026-09-16 02:30 - Bruno DELNOZ
#   MAJOR:
#   - Adds interval-based CAPTURE sessions while preserving the existing CLI,
#     runtime layout, naming scheme and capture/check/crack separation.
#   ADDED:
#   - --interval MINUTES for CAPTURE. Each interval is a complete independent
#     airodump-ng slice with its own unique PREFIX and normal -01 CSV/CAP files.
#   - --accept compatibility option for non-interactive acceptance semantics.
#     The current capture flow has no confirmation prompt to auto-answer; sudo
#     authentication remains handled by sudo and is never bypassed by --accept.
#   - Per-interval post-processing: when --post-process is enabled, each finished
#     interval is copied/filtered/OUI-enriched before the next interval starts.
#   - Finite duration remainder support: if --duration is not exactly divisible
#     by the interval length, the final slice uses the remaining seconds.
#   - Infinite interval mode: --infinite --interval N (or no --duration with
#     --interval N) repeats N-minute slices until interruption.
#   CHANGED:
#   - --duration remains expressed in SECONDS for backward compatibility.
#   - --interval is expressed in MINUTES as requested for human-friendly loops.
#   - Monitor mode is entered once for the whole capture session and preserved
#     between slices; only airodump-ng is stopped/restarted at each boundary.
#   - --archive-old still runs once, before the first slice only.
#   PRESERVED:
#   - Existing .results/{cap,csv,filtered,enriched,generated,logs,tmp,archive}
#     layout and timestamp/collision-safe prefix generation.
#   - Existing --post-process output formats and filenames.
#   - Existing behavior when --interval is omitted.
#
# v1.0.13-SOLO414 - 2026-09-15 20:43 - Bruno DELNOZ
#   FIXED:
#   - Reworked internal sudo authentication after the v1.0.12 /dev/tty flow
#     still failed on the target Kali host with "password is required".
#   - `sudo -v` now runs normally on the inherited controlling terminal instead
#     of redirecting stdin/stdout through /dev/tty.
#   - The post-authentication check now uses `sudo -n true` on the same terminal.
#   - airodump-ng no longer executes an inner sudo from the PTY created by
#     util-linux `script`; this avoids tty-bound sudo timestamp mismatches.
#   ADDED:
#   - run_privileged() wrapper: root executes directly, normal user executes
#     through the already validated `sudo -n` ticket.
#   CHANGED:
#   - Timed/infinite airodump command arrays are now sudo-free.
#   - The outer `script` PTY wrapper is elevated instead of the command inside
#     the PTY, preserving the live airodump display without a second sudo prompt.
#
# v1.0.12-SOLO414 - 2026-09-15 20:35 - Bruno DELNOZ
#   FIXED:
#   - Internal sudo authentication no longer depends on the script stdin stream.
#   - When sudo credentials are not already cached, authentication is performed
#     explicitly through /dev/tty with `sudo -v`.
#   - Prevents the observed immediate `sudo: ... password is required` failure
#     when the script is started normally without external `sudo`.
#   ADDED:
#   - Root detection: no sudo authentication prompt when EUID=0.
#   - Sudo timestamp keepalive for long captures/attacks.
#   - Automatic keepalive cleanup on EXIT, INT, TERM and HUP.
#   - Explicit verification of the sudo ticket after interactive validation.
#   CHANGED:
#   - Privileged child commands use `sudo -n` after one-time authentication,
#     so capture PTYs/logging never receive an unexpected password prompt.
#   - --install now uses the same validated internal sudo path.
#
# v1.0.11-SOLO414 - 2026-09-15 20:24 - Bruno DELNOZ
#   FIXED:
#   - Restores the live airodump-ng terminal display during CAPTURE.
#   - Replaces the normal `2>&1 | tee` capture path with a pseudo-terminal
#     provided by util-linux `script`, because piping airodump-ng through tee
#     removes its TTY and its full-screen display can disappear/turn blank.
#   - Keeps the airodump session logged while preserving the interactive screen.
#   ADDED:
#   - `script` command as an explicit CAPTURE prerequisite.
#   - `util-linux` in the automated prerequisite installation package set.
#   - A direct fallback to normal terminal execution if PTY logging fails.
#   CHANGED:
#   - Default non-spinner capture now runs inside a PTY and remains visible live.
#   - Spinner mode still intentionally hides the airodump full-screen UI and
#     shows only the spinner.
#
# v1.0.10-SOLO414 - 2026-09-15 20:18 - Bruno DELNOZ
#   FIXED:
#   - Timed CAPTURE now stops reliably when --duration/-d is reached.
#   - Replaced plain `timeout DURATION` with a foreground timeout using SIGINT
#     for graceful airodump-ng shutdown and a hard SIGKILL fallback after 3s.
#   - Prevents airodump-ng from remaining alive indefinitely when it does not
#     terminate on GNU timeout's default SIGTERM.
#   - Preserves CAP/CSV flush opportunity by sending SIGINT before the hard kill.
#   CHANGED:
#   - Timed capture command now uses:
#       timeout --foreground --signal=INT --kill-after=3s <duration>s ...
#   - Help now documents the bounded graceful-shutdown window for timed capture.
#
# v1.0.9-SOLO414 - 2026-09-14 07:09 - Bruno DELNOZ
#   ADDED:
#   - Canonical SOLO control aliases: --exec/-exe, --simulate/-s,
#     --prerequis/-pr, --install/-i, --stop/-st, --purge/-pu.
#   - --dest_dir / --dest-dir to override the default .results runtime root.
#   - Bounded non-interactive CHECK execution with timeout and stdin closed.
#   - Runtime PID file so --stop can stop an active invocation started by this script.
#   - Prerequisite version detection and exact installation recommendation.
#   - Post-execution numbered summaries and explicit simulation summaries.
#   CHANGED:
#   - Canonical real execution is now --exec --<business-action>.
#   - Canonical simulation is now --simulate --<business-action>, without --exec.
#   - Historical --dry-run is retained as a compatibility alias for --simulate.
#   - Historical --prereq/--check-prereq aliases are retained and mapped to --prerequis.
#   - Historical --clean-runtime is retained and mapped to --purge.
#   - --interface remains available only in long form because -i is reserved by --install.
#   - --station remains available only in long form because -s is reserved by --simulate.
#   - Positional business actions and positional interface syntax are removed from the parser.
#   FIXED:
#   - CAPTURE remains capture-only and never launches aircrack-ng.
#   - CHECK and CRACK remain separate explicit business actions.
#   - Simulation no longer requires --exec.
#   - Help/parser/examples are aligned on one canonical CLI.
#   - Header date now includes time.
#   REMOVED:
#   - Legacy positional CAPTURE/ATTACK/DONE/NODONE/NORMAL action tokens.
#   - Conflicting historical short aliases -i for --interface and -s for --station.
#
# v1.0.8-SOLO413 - 2026-09-14 - Bruno DELNOZ
#   - Rebuilt script around canonical SOLO413-style CLI.
#   - Uses --exec --capture / --exec --check / --exec --crack.
#   - Keeps --exec gate mandatory for operational actions.
#   - Keeps info/maintenance commands executable without --exec.
#   - Adds --prereq, --check-prereq, --doctor, --init, --show-paths.
#   - Adds --dry-run for operational actions.
#   - Adds --clean-tmp and --clean-runtime.
#   - Adds --version.
#   - Keeps -X / --exclusions-file.
#   - Keeps .results/ runtime tree.
#   - CAPTURE never launches aircrack-ng.
#   - CHECK/CRACK are separate explicit actions.
#   - Keeps generated package as script-only ZIP.
#
# v1.0.7 - 2026-09-14
#   - Added missing prereq/doctor/control arguments.
#
# v1.0.6 - 2026-09-14
#   - First rebuilt --exec + separated action CLI.
#
# v1.0.5 - 2026-09-14
#   - Removed automatic aircrack-ng from CAPTURE.
#
# v1.0.4 - 2026-09-14
#   - Clean runtime moved under .results/.
#
# v1.0.2 - 2026-09-14
#   - Integrated useful bof.sh functions.
#
# v1.0.1 - 2026-09-14
#   - Delegated monitor/managed to tools/monitor/set_unset_to_monitor.sh.
#
# v1.0.0 - 2026-09-14
#   - Initial merged version from all.sh / all_woeking2.sh / all_working.sh.
# ==============================================================================

set -u
IFS=$'\n\t'

VERSION="v3.0.0"
SCRIPT_DATE="2026-09-23 23:37"
SCRIPT_AUTHOR="Bruno DELNOZ"
SCRIPT_EMAIL="bruno.delnoz@protonmail.com"

# ==============================================================================
# PATHS
# ==============================================================================

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$BASE_DIR"
MONITOR_HELPER="$BASE_DIR/set_unset_to_monitor.sh"

MYINFO_DIR="$BASE_DIR/myinfo"
EXCLUSION_FILE="$MYINFO_DIR/exclusions.txt"
OUI_FILE="$MYINFO_DIR/oui.txt"
OUI_BACKUP_FILE="$MYINFO_DIR/oui.txt.bak"
OUI_SOURCE_URL="${WIFI_AIR_SUITE_OUI_URL:-https://standards-oui.ieee.org/oui/oui.txt}"

RUNTIME_DIR="$BASE_DIR/.results"
CAP_DIR="$RUNTIME_DIR/cap"
CSV_DIR="$RUNTIME_DIR/csv"
FILTERED_DIR="$RUNTIME_DIR/filtered"
ENRICHED_DIR="$RUNTIME_DIR/enriched"
GENERATED_DIR="$RUNTIME_DIR/generated"
LOG_DIR="$RUNTIME_DIR/logs"
TMP_DIR="$RUNTIME_DIR/tmp"
ARCHIVE_DIR="$RUNTIME_DIR/archive"
PID_FILE="$TMP_DIR/wifi_air_suite.pid"

# ==============================================================================
# DEFAULTS / STATE
# ==============================================================================

DEFAULT_IFACE="${WLAN_IFACE:-wlan1}"

EXEC_MODE=0
DRY_RUN=0
SIMULATE_MODE=0
ACTION=""

REQUESTED_IFACE="$DEFAULT_IFACE"
WLAN_IFACE="$DEFAULT_IFACE"
BASE_WLAN_IFACE="$DEFAULT_IFACE"

DURATION=""
INFINITE=0
INTERVAL_MINUTES=""
POST_PROCESS=0
ACCEPT_MODE=0
OPEN_KATE=0
ARCHIVE_OLD=0
SPINNER=0
NO_LOG=0
MIN_OUI_ENTRIES=10000

OFFSET="1"
ALL_FILES=0
CAP_FILE=""
CSV_FILE=""

BSSID_FILTER=""
CHANNEL_FILTER=""
STATION_FILTER=""
WORDLIST=""
DEAUTH_COUNT=10

PREFIX=""
GLOBAL_LOG_FILE=""
AIRODUMP_LOG_FILE=""
ACTION_LOG_FILE=""

MONITOR_CHANGED_BY_THIS_SCRIPT=0
SUDO_KEEPALIVE_PID=""
SUDO_AUTHENTICATED=0

declare -a EXCLUSIONS=()

# ==============================================================================
# OUTPUT
# ==============================================================================

say()  { printf '%s\n' "$*"; }
info() { printf '[*] %s\n' "$*"; }
ok()   { printf '[OK] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err()  { printf '[KO] %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

is_operational_action() {
    case "${1:-}" in
        capture|check|crack|attack-hosts|attack-preauth|test-injection)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

need_exec() {
    if (( SIMULATE_MODE == 1 )); then
        return 0
    fi

    if (( EXEC_MODE != 1 )); then
        err "Action opérationnelle refusée : --exec est obligatoire pour l'exécution réelle."
        err "Exemple : ./wifi_air_suite.sh --exec --capture --interface wlan0 -d 20 --post-process"
        err "Simulation : ./wifi_air_suite.sh --simulate --capture --interface wlan0 -d 20 --post-process"
        exit 2
    fi
}

validate_execution_gate() {
    if (( EXEC_MODE == 1 && SIMULATE_MODE == 1 )); then
        die "--exec et --simulate sont mutuellement exclusifs."
    fi

    if is_operational_action "$ACTION"; then
        if (( EXEC_MODE == 0 && SIMULATE_MODE == 0 )); then
            die "L'action '$ACTION' exige --exec ou --simulate."
        fi
    fi
}

valid_mac() {
    [[ "${1:-}" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]
}

valid_channel() {
    case "${1:-}" in
        1|2|3|4|5|6|7|8|9|10|11|12|13|14|36|40|44|48|52|56|60|64|100|104|108|112|116|120|124|128|132|136|140|144|149|153|157|161|165)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

normalize_mac() {
    printf '%s' "$1" | tr 'a-f' 'A-F'
}

is_iface_arg() {
    [[ "${1:-}" =~ ^wlan[0-9]+(mon)?$ ]]
}

derive_base_iface() {
    local iface="$1"
    if [[ "$iface" =~ ^(wlan[0-9]+)mon$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    else
        printf '%s\n' "$iface"
    fi
}

# ==============================================================================
# HELP
# ==============================================================================

show_help() {
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  wifi_air_suite.sh – $VERSION – $SCRIPT_DATE
  Author : $SCRIPT_AUTHOR <$SCRIPT_EMAIL>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DESCRIPTION:
  Unified Wi-Fi capture/check/crack/lab-action tool.
  CAPTURE is strictly capture-only: it never launches aircrack-ng.
  CHECK and CRACK are separate explicit business actions.

USAGE:
  ./wifi_air_suite.sh --help
  ./wifi_air_suite.sh --prerequis
  ./wifi_air_suite.sh --install
  ./wifi_air_suite.sh --simulate --<business-action> [OPTIONS]
  ./wifi_air_suite.sh --exec --<business-action> [OPTIONS]

CONTROL ACTIONS:
  --help,       -h
      Show this complete help.

  --exec,       -exe
      Authorize real execution of exactly one business action.

  --simulate,   -s
      Dry-run exactly one business action.
      Does not require --exec and performs no privileged/system/network change.

  --prerequis,  -pr
      Check prerequisites and print present/missing state, detected version
      when available, and exact recommended action when something is missing.

  --install,    -i
      Install the supported prerequisite package set with APT.
      This is a control action, not the Wi-Fi interface option.

  --stop,       -st
      Stop the currently active invocation registered by this script, if any.

  --changelog,  -ch
      Show the complete internal append-only changelog.

  --purge,      -pu
      Purge runtime artifacts managed by this script under the active runtime root.
      myinfo/ and source/documentation files are never removed.

BUSINESS ACTIONS:
  --capture
      Capture with airodump-ng only.
      Never runs aircrack-ng, CHECK, CRACK or any attack action implicitly.

  --check
      Inspect the selected/latest .cap file.
      Runs aircrack-ng in bounded, non-interactive inspection mode.

  --crack
      Explicit aircrack-ng cracking mode.
      Requires --wordlist FILE and --bssid MAC.

  --attack-hosts
      Authorized/lab deauthentication action using AP/station pairs from CSV.

  --attack-preauth
      Authorized/lab fake-authentication action using AP/station pairs from CSV.

  --test-injection
      Authorized/lab aireplay-ng injection test.

INFORMATION / MAINTENANCE:
  --doctor
      Print paths, prerequisite state, interfaces and runtime inventory.

  --init
      Create expected myinfo/ and runtime directories.

  --show-paths
      Print resolved paths.

  --print-config
      Print resolved configuration.

  --list-captures
      List .cap files from the active runtime.

  --list-csv
      List CSV files from the active runtime.

  --clean-tmp
      Clean only the runtime tmp directory.

  --clean-runtime
      Compatibility alias for --purge.

  --update-oui
      Update myinfo/oui.txt from the IEEE Registration Authority public MA-L/OUI
      listing. The current file is preserved as myinfo/oui.txt.bak and is only
      replaced after the downloaded data passes validation.
      No --exec gate is required.
      Source can be overridden for testing with WIFI_AIR_SUITE_OUI_URL.

  --version
      Print script version.

COMPATIBILITY ALIASES:
  --dry-run
      Alias for --simulate.

  --prereq
  --prereqs
  --prerequisite
  --prerequisites
  --check-prereq
  --check-prereqs
      Compatibility aliases for --prerequis.

BUSINESS OPTIONS:
  --interface IFACE
      Wi-Fi interface.
      Examples: wlan0, wlan1, wlan2, wlan0mon
      Default: $DEFAULT_IFACE

      NOTE:
        Historical -i is intentionally not used for --interface because
        -i is the reserved SOLO alias for --install.

  -d, --duration SECONDS
      Timed capture duration in seconds.
      If omitted, capture is infinite until CTRL-C.
      Timed capture sends SIGINT at the requested duration for a clean
      airodump-ng shutdown, then forces SIGKILL after 3 additional seconds
      only if airodump-ng did not terminate.

  --infinite
      Force infinite capture.

  --interval MINUTES
      Split CAPTURE into independent intervals of MINUTES.
      Each interval gets its own normal unique capture prefix and CSV/CAP files.
      --duration stays in seconds for backward compatibility.
      Example: --duration 3600 --interval 10 = 6 x 10-minute captures.
      If the total duration is not divisible by the interval, the final capture
      uses the remaining seconds. Without --duration, intervals repeat until
      CTRL-C.

  --post-process
      Generate copied raw CSV, filtered CSV, filtered Markdown and
      OUI-enriched CSV outputs. With --interval, post-process runs after EACH
      completed interval before the next interval starts.

  --open-kate
      Open each newly generated *.filtered.md in Kate immediately after creation.
      Requires --post-process. Kate is launched asynchronously and does not block
      the next capture interval.

  --accept
      Compatibility option for non-interactive acceptance semantics.
      The current CAPTURE path has no confirmation prompt to auto-answer.
      This option never bypasses sudo authentication.

  --no-post-process
      Disable post-processing.

  --archive-old
      Move older runtime result files to archive/*.done before capture.

  --spinner
      Enable spinner for timed capture.
      This intentionally hides the full-screen airodump-ng UI.

  --no-spinner
      Disable spinner.
      Default.
      The airodump-ng scan table is displayed live in the terminal through
      a pseudo-terminal while the same terminal session is logged.

  --nolog
  --no-log
      Disable persistent runtime .log files for this invocation.
      CAP/CSV capture files and post-processing outputs are still generated.
      In live CAPTURE mode, airodump-ng remains visible directly in the current
      terminal without creating the PTY terminal log.
      Default: logging enabled.

SELECTION OPTIONS:
  -o, --offset N
      Select Nth newest file.
      1 = newest, 2 = previous, etc.
      Default: 1

  --all
      Process all CSV files where supported.

  --cap-file FILE
      Select an explicit .cap file.

  --csv-file FILE
      Select an explicit .csv file.

  -b, --bssid MAC
      Limit an applicable action to one BSSID.

  --channel N
      Restrict CAPTURE to one Wi-Fi channel.
      Requires --capture and --bssid.
      Example: --bssid AA:BB:CC:DD:EE:FF --channel 4
      Without --channel, CAPTURE keeps the existing multi-channel scan list.

  --station MAC
      Limit an applicable action to one station/client MAC.

      NOTE:
        Historical -s is intentionally not used for --station because
        -s is the reserved SOLO alias for --simulate.

  -X, --exclusions-file FILE
      MAC exclusion file.
      Default: $EXCLUSION_FILE

  -w, --wordlist FILE
      Wordlist for --crack.

  --deauth-count N
      Deauthentication frame count per pair.
      Default: $DEAUTH_COUNT

  --dest_dir DIR
  --dest-dir DIR
      Override the runtime result root.
      Default: $RUNTIME_DIR

DEFAULT FILES / DIRECTORIES:
  User input:
    $MYINFO_DIR/exclusions.txt
    $MYINFO_DIR/oui.txt

  Runtime root:
    $RUNTIME_DIR

  Runtime layout:
    cap/
    csv/
    filtered/
    enriched/
    generated/
    logs/
    tmp/
    archive/

EXAMPLES:
  ./wifi_air_suite.sh --help
  ./wifi_air_suite.sh --prerequis
  ./wifi_air_suite.sh -pr
  ./wifi_air_suite.sh --install
  ./wifi_air_suite.sh --doctor
  ./wifi_air_suite.sh --update-oui
  ./wifi_air_suite.sh --simulate --update-oui

  ./wifi_air_suite.sh --simulate --capture --interface wlan0 -d 20 --post-process
  ./wifi_air_suite.sh --exec --capture --interface wlan0 -d 20 --post-process
  ./wifi_air_suite.sh --exec --capture --interface wlan0 --duration 3600 --interval 10 --post-process --open-kate --accept
  ./wifi_air_suite.sh --exec --capture --interface wlan0 --infinite --interval 10 --post-process --accept
  ./wifi_air_suite.sh --exec --capture --interface wlan0 --infinite --post-process
  ./wifi_air_suite.sh --exec --capture --interface wlan0 --infinite --interval 10 --post-process --accept --nolog
  ./wifi_air_suite.sh --exec --capture --interface wlan0 --infinite --post-process --nolog
  ./wifi_air_suite.sh --exec --capture --interface wlan0 --bssid AA:BB:CC:DD:EE:FF --channel 4 --duration 300 --post-process --nolog

  ./wifi_air_suite.sh --simulate --check --offset 1
  ./wifi_air_suite.sh --exec --check --offset 1
  ./wifi_air_suite.sh --exec --check --cap-file .results/cap/capture.cap --bssid AA:BB:CC:DD:EE:FF

  ./wifi_air_suite.sh --simulate --crack --cap-file .results/cap/capture.cap --bssid AA:BB:CC:DD:EE:FF --wordlist ./wordlist.txt
  ./wifi_air_suite.sh --exec --crack --cap-file .results/cap/capture.cap --bssid AA:BB:CC:DD:EE:FF --wordlist ./wordlist.txt

  ./wifi_air_suite.sh --simulate --attack-hosts --interface wlan1 --offset 1
  ./wifi_air_suite.sh --exec --attack-hosts --interface wlan1 --offset 1
  ./wifi_air_suite.sh --exec --attack-preauth --interface wlan1 --offset 1
  ./wifi_air_suite.sh --exec --test-injection --interface wlan1

  ./wifi_air_suite.sh --stop
  ./wifi_air_suite.sh --purge

SUDO BEHAVIOR:
  - Normal invocation does not require external sudo.
  - The script lets sudo prompt normally on the controlling terminal.
  - Authentication happens once before the business action.
  - Later privileged commands use the validated ticket non-interactively.
  - The live airodump PTY is elevated from outside the PTY, preventing a second
    tty-scoped sudo authentication request.
  - A keepalive refreshes the ticket during long-running operations.
  - Starting the complete script with sudo remains supported but is not required.

IMPORTANT BEHAVIOR:
  - No argument: help only, no business action.
  - --exec alone: invalid.
  - --simulate alone: invalid for this multi-action script.
  - Exactly one business action is required for --exec/--simulate.
  - CAPTURE never triggers CHECK, CRACK or ATTACK implicitly.
  - --crack requires both --wordlist and --bssid.
  - Actions using aireplay-ng are for owned/authorized lab environments only.

EOF
}
show_changelog() {
    awk '
        /^# CHANGELOG$/ {
            in_changelog = 1
            separator_count = 0
            next
        }

        in_changelog && /^# =+$/ {
            separator_count++
            if (separator_count == 1) {
                next
            }
            if (separator_count == 2) {
                exit
            }
        }

        in_changelog && separator_count == 1 {
            line = $0
            sub(/^# ?/, "", line)
            print line
        }
    ' "$0"
}

# ==============================================================================
# ARGUMENTS
# ==============================================================================

set_action() {
    local new_action="$1"
    if [[ -n "$ACTION" ]]; then
        die "Une seule action à la fois : déjà '$ACTION', reçu '$new_action'"
    fi
    ACTION="$new_action"
}

parse_args() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --exec|-exe)
                EXEC_MODE=1
                shift
                ;;

            --simulate|-s|--dry-run)
                SIMULATE_MODE=1
                DRY_RUN=1
                shift
                ;;

            --capture)
                set_action "capture"
                shift
                ;;

            --check)
                set_action "check"
                shift
                ;;

            --crack)
                set_action "crack"
                shift
                ;;

            --attack-hosts)
                set_action "attack-hosts"
                shift
                ;;

            --attack-preauth|--attack-pre-auth)
                set_action "attack-preauth"
                shift
                ;;

            --test-injection)
                set_action "test-injection"
                shift
                ;;

            --prerequis|-pr|--prereq|--prereqs|--prerequisite|--prerequisites|--check-prereq|--check-prereqs)
                set_action "prerequis"
                shift
                ;;

            --install|-i)
                set_action "install"
                shift
                ;;

            --stop|-st)
                set_action "stop"
                shift
                ;;

            --purge|-pu|--clean-runtime)
                set_action "purge"
                shift
                ;;

            --doctor)
                set_action "doctor"
                shift
                ;;

            --init)
                set_action "init"
                shift
                ;;

            --show-paths)
                set_action "show-paths"
                shift
                ;;

            --print-config)
                set_action "print-config"
                shift
                ;;

            --list-captures)
                set_action "list-captures"
                shift
                ;;

            --list-csv)
                set_action "list-csv"
                shift
                ;;

            --clean-tmp)
                set_action "clean-tmp"
                shift
                ;;

            --update-oui)
                set_action "update-oui"
                shift
                ;;

            --version)
                say "$VERSION"
                exit 0
                ;;

            --help|-h)
                show_help
                exit 0
                ;;

            --changelog|-ch)
                show_changelog
                exit 0
                ;;

            --interface)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                REQUESTED_IFACE="$2"
                shift 2
                ;;

            -d|--duration)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                [[ "$2" =~ ^[1-9][0-9]*$ ]] || die "Durée invalide : $2"
                DURATION="$2"
                INFINITE=0
                shift 2
                ;;

            --infinite)
                INFINITE=1
                DURATION=""
                shift
                ;;

            --interval)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                [[ "$2" =~ ^[1-9][0-9]*$ ]] || die "Intervalle invalide (minutes) : $2"
                INTERVAL_MINUTES="$2"
                shift 2
                ;;

            --post-process)
                POST_PROCESS=1
                shift
                ;;

            --open-kate)
                OPEN_KATE=1
                shift
                ;;

            --no-post-process)
                POST_PROCESS=0
                shift
                ;;

            --accept)
                ACCEPT_MODE=1
                shift
                ;;

            --archive-old)
                ARCHIVE_OLD=1
                shift
                ;;

            --no-spinner)
                SPINNER=0
                shift
                ;;

            --spinner)
                SPINNER=1
                shift
                ;;

            --nolog|--no-log)
                NO_LOG=1
                shift
                ;;

            -o|--offset)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                [[ "$2" =~ ^[1-9][0-9]*$ ]] || die "Offset invalide : $2"
                OFFSET="$2"
                shift 2
                ;;

            --all)
                ALL_FILES=1
                shift
                ;;

            --cap-file)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                CAP_FILE="$2"
                shift 2
                ;;

            --csv-file)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                CSV_FILE="$2"
                shift 2
                ;;

            -b|--bssid)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                valid_mac "$2" || die "BSSID invalide : $2"
                BSSID_FILTER="$(normalize_mac "$2")"
                shift 2
                ;;

            --channel)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                valid_channel "$2" || die "Canal invalide/non supporté par la liste de capture : $2"
                CHANNEL_FILTER="$2"
                shift 2
                ;;

            --station)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                valid_mac "$2" || die "Station MAC invalide : $2"
                STATION_FILTER="$(normalize_mac "$2")"
                shift 2
                ;;

            -X|--exclusions-file)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                EXCLUSION_FILE="$2"
                shift 2
                ;;

            -w|--wordlist)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                WORDLIST="$2"
                shift 2
                ;;

            --deauth-count)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                [[ "$2" =~ ^[1-9][0-9]*$ ]] || die "Deauth count invalide : $2"
                DEAUTH_COUNT="$2"
                shift 2
                ;;

            --dest_dir|--dest-dir)
                [[ $# -ge 2 ]] || die "Valeur manquante après $1"
                set_runtime_root "$2"
                shift 2
                ;;

            *)
                die "Argument inconnu ou syntaxe positionnelle obsolète : $1"
                ;;
        esac
    done

    [[ -n "$ACTION" ]] || {
        if (( EXEC_MODE == 1 || SIMULATE_MODE == 1 )); then
            die "--exec/--simulate exige exactement une action métier explicite."
        fi
        show_help
        exit 0
    }

    validate_execution_gate

    if [[ -n "$INTERVAL_MINUTES" && "$ACTION" != "capture" ]]; then
        die "--interval est disponible uniquement avec --capture."
    fi

    if [[ -n "$CHANNEL_FILTER" ]]; then
        [[ "$ACTION" == "capture" ]] || die "--channel est disponible uniquement avec --capture."
        [[ -n "$BSSID_FILTER" ]] || die "--channel exige --bssid MAC pour une capture ciblée."
    fi

    if (( OPEN_KATE == 1 )); then
        [[ "$ACTION" == "capture" ]] || die "--open-kate est disponible uniquement avec --capture."
        (( POST_PROCESS == 1 )) || die "--open-kate exige --post-process."
    fi

    BASE_WLAN_IFACE="$(derive_base_iface "$REQUESTED_IFACE")"
    WLAN_IFACE="$REQUESTED_IFACE"
}
# ==============================================================================
# DIRS / LOGS / CLEAN
# ==============================================================================

set_runtime_root() {
    local requested="$1"

    if [[ "$requested" == /* ]]; then
        RUNTIME_DIR="$requested"
    else
        RUNTIME_DIR="$BASE_DIR/$requested"
    fi

    CAP_DIR="$RUNTIME_DIR/cap"
    CSV_DIR="$RUNTIME_DIR/csv"
    FILTERED_DIR="$RUNTIME_DIR/filtered"
    ENRICHED_DIR="$RUNTIME_DIR/enriched"
    GENERATED_DIR="$RUNTIME_DIR/generated"
    LOG_DIR="$RUNTIME_DIR/logs"
    TMP_DIR="$RUNTIME_DIR/tmp"
    ARCHIVE_DIR="$RUNTIME_DIR/archive"
    PID_FILE="$TMP_DIR/wifi_air_suite.pid"
}

ensure_dirs() {
    mkdir -p \
        "$MYINFO_DIR" \
        "$RUNTIME_DIR" \
        "$CAP_DIR" \
        "$CSV_DIR" \
        "$FILTERED_DIR" \
        "$ENRICHED_DIR" \
        "$GENERATED_DIR" \
        "$LOG_DIR" \
        "$TMP_DIR" \
        "$ARCHIVE_DIR"

    [[ -f "$EXCLUSION_FILE" ]] || : > "$EXCLUSION_FILE"
}

generate_prefix() {
    local timestamp candidate i
    timestamp="$(date +'%Y%m%d_%H%M%S')"
    i=1

    while :; do
        candidate="${timestamp}_${i}"
        if [[ ! -e "$CAP_DIR/${candidate}-01.cap" \
           && ! -e "$CAP_DIR/${candidate}-01.csv" \
           && ! -e "$LOG_DIR/${candidate}.log" \
           && ! -e "$LOG_DIR/airodump-${candidate}.log" ]]; then
            PREFIX="$candidate"
            return 0
        fi
        ((i++))
    done
}

setup_logs() {
    [[ -n "$PREFIX" ]] || generate_prefix

    if (( NO_LOG == 1 )); then
        GLOBAL_LOG_FILE="/dev/null"
        AIRODUMP_LOG_FILE="/dev/null"
        ACTION_LOG_FILE="/dev/null"
        return 0
    fi

    GLOBAL_LOG_FILE="$LOG_DIR/${PREFIX}.log"
    AIRODUMP_LOG_FILE="$LOG_DIR/airodump-${PREFIX}.log"
    ACTION_LOG_FILE="$LOG_DIR/${ACTION}-${PREFIX}.log"

    {
        echo "script=wifi_air_suite.sh"
        echo "version=$VERSION"
        echo "date=$(date --iso-8601=seconds 2>/dev/null || date)"
        echo "action=$ACTION"
        echo "exec=$EXEC_MODE"
        echo "dry_run=$DRY_RUN"
        echo "iface=$REQUESTED_IFACE"
        echo "runtime=$RUNTIME_DIR"
        echo "prefix=$PREFIX"
    } >> "$GLOBAL_LOG_FILE"
}

runtime_chown() {
    local owner group
    owner="${SUDO_USER:-$(id -un 2>/dev/null || printf nox)}"
    group="$(id -gn "$owner" 2>/dev/null || id -gn 2>/dev/null || printf nox)"

    if command -v sudo >/dev/null 2>&1 && id "$owner" >/dev/null 2>&1; then
        run_privileged chown -R "$owner:$group" "$RUNTIME_DIR" "$MYINFO_DIR" 2>/dev/null || true
    fi
}

archive_old() {
    local dir f base dest
    mkdir -p "$ARCHIVE_DIR"

    for dir in "$CAP_DIR" "$CSV_DIR" "$FILTERED_DIR" "$ENRICHED_DIR" "$GENERATED_DIR"; do
        [[ -d "$dir" ]] || continue

        while IFS= read -r -d '' f; do
            [[ "$f" == *.done ]] && continue
            base="$(basename "$f")"
            dest="$ARCHIVE_DIR/${base}.done"
            mv -f -- "$f" "$dest" 2>/dev/null || true
        done < <(find "$dir" -maxdepth 1 -type f -print0 2>/dev/null)
    done
}

clean_tmp_impl() {
    mkdir -p "$TMP_DIR"
    rm -f "$TMP_DIR"/* 2>/dev/null || true
}

auto_clean_tmp() {
    local count size
    mkdir -p "$TMP_DIR"

    count="$(find "$TMP_DIR" -type f 2>/dev/null | wc -l | awk '{print $1}')"
    size="$(du -sm "$TMP_DIR" 2>/dev/null | awk '{print $1}')"
    size="${size:-0}"

    if (( count > 100 || size > 10 )); then
        info "Nettoyage automatique tmp ($count fichiers, ${size}M)."
        clean_tmp_impl
    fi
}

clean_runtime_impl() {
    ensure_dirs
    find "$CAP_DIR" "$CSV_DIR" "$FILTERED_DIR" "$ENRICHED_DIR" "$GENERATED_DIR" "$LOG_DIR" "$TMP_DIR" \
        -maxdepth 1 -type f -delete 2>/dev/null || true
}

# ==============================================================================
# COMMAND CHECKS
# ==============================================================================

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

need_cmd() {
    has_cmd "$1" || die "Commande manquante : $1"
}

check_cmd_line() {
    local cmd="$1"
    if has_cmd "$cmd"; then
        printf '[OK] %-18s %s\n' "$cmd" "$(command -v "$cmd")"
        return 0
    fi

    printf '[KO] %-18s missing\n' "$cmd"
    return 1
}

common_deps() {
    local cmd
    for cmd in bash awk sed grep head ls mkdir date tee tr wc find du cp mv rm id sudo iw ip sync; do
        need_cmd "$cmd"
    done
}

capture_deps() {
    common_deps
    need_cmd airodump-ng
    need_cmd iwconfig
    need_cmd timeout

    if (( NO_LOG == 0 )); then
        need_cmd script
    fi
}

check_deps() {
    common_deps
    need_cmd aircrack-ng
}

crack_deps() {
    common_deps
    need_cmd aircrack-ng
}

attack_deps() {
    common_deps
    need_cmd aireplay-ng
    need_cmd iwconfig
}

sudo_keepalive_stop() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
    SUDO_KEEPALIVE_PID=""
}

sudo_keepalive_start() {
    local parent_pid

    (( EUID == 0 )) && return 0

    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        return 0
    fi

    parent_pid="$$"

    (
        sleeper_pid=""
        trap 'if [[ -n "${sleeper_pid:-}" ]]; then kill "$sleeper_pid" 2>/dev/null || true; fi; exit 0' INT TERM HUP

        while kill -0 "$parent_pid" 2>/dev/null; do
            sleep 45 &
            sleeper_pid="$!"
            wait "$sleeper_pid" 2>/dev/null || exit 0
            sleeper_pid=""
            sudo -n true >/dev/null 2>&1 || exit 0
        done
    ) >/dev/null 2>&1 &

    SUDO_KEEPALIVE_PID="$!"
}

run_privileged() {
    if (( EUID == 0 )); then
        "$@"
    else
        sudo -n "$@"
    fi
}

sudo_ready() {
    # Root invocation remains supported.
    if (( EUID == 0 )); then
        SUDO_AUTHENTICATED=1
        info "Sudo                : déjà root, aucune authentification nécessaire"
        return 0
    fi

    # Fast path: current terminal already has a valid sudo timestamp.
    if sudo -n true >/dev/null 2>&1; then
        SUDO_AUTHENTICATED=1
        info "Sudo                : credentials déjà valides"
        sudo_keepalive_start
        return 0
    fi

    # Important:
    # Do NOT redirect sudo through /dev/tty here. sudo already knows how to open
    # the controlling terminal for password entry. The v1.0.12 redirection path
    # was observed to print the prompt and then fail immediately with
    # "sudo: ... password is required" on the target Kali host.
    if [[ ! -t 0 && ! -e /dev/tty ]]; then
        die "Sudo nécessite un terminal interactif. Relance depuis un terminal normal."
    fi

    info "Sudo                : authentification requise"

    if ! sudo -v -p "[sudo] Mot de passe de %u : "; then
        die "Authentification sudo refusée ou interrompue."
    fi

    # Validate the ticket immediately on the same controlling terminal.
    if ! sudo -n true >/dev/null 2>&1; then
        die "Le ticket sudo n'est pas utilisable après authentification."
    fi

    SUDO_AUTHENTICATED=1
    sudo_keepalive_start
    ok "Sudo authentifié pour cette exécution."
}

# ==============================================================================
# INFO / CONTROL ACTIONS
# ==============================================================================

command_version() {
    local cmd="$1"
    local version=""

    case "$cmd" in
        bash)
            version="$(bash --version 2>/dev/null | head -n1)"
            ;;
        sudo)
            version="$(sudo --version 2>/dev/null | head -n1)"
            ;;
        timeout|script|date|cp|mv|rm|mkdir|head|tr|wc|ls|du)
            version="$("$cmd" --version 2>/dev/null | head -n1)"
            ;;
        awk)
            version="$(awk --version 2>/dev/null | head -n1 || true)"
            ;;
        sed)
            version="$(sed --version 2>/dev/null | head -n1 || true)"
            ;;
        grep)
            version="$(grep --version 2>/dev/null | head -n1 || true)"
            ;;
        find)
            version="$(find --version 2>/dev/null | head -n1 || true)"
            ;;
        aircrack-ng)
            version="$(aircrack-ng --help 2>&1 | head -n1)"
            ;;
        airodump-ng)
            version="$(airodump-ng --help 2>&1 | head -n1)"
            ;;
        aireplay-ng)
            version="$(aireplay-ng --help 2>&1 | head -n1)"
            ;;
        iw)
            version="$(iw --version 2>&1 | head -n1)"
            ;;
        iwconfig)
            version="$(iwconfig --version 2>&1 | head -n1)"
            ;;
        ip)
            version="$(ip -V 2>&1 | head -n1)"
            ;;
        nmcli)
            version="$(nmcli --version 2>&1 | head -n1)"
            ;;
        curl)
            version="$(curl --version 2>&1 | head -n1)"
            ;;
        wget)
            version="$(wget --version 2>&1 | head -n1)"
            ;;
        *)
            version=""
            ;;
    esac

    printf '%s\n' "${version:-n/a}"
}

run_prerequis() {
    local rc=0 cmd state version
    local -a commands=(
        bash sudo timeout script aircrack-ng airodump-ng aireplay-ng
        iw iwconfig ip nmcli awk sed grep tee find du wc ls cp mv rm mkdir
        head tr id date sync curl
    )

    say "wifi_air_suite.sh $VERSION — PREREQUIS"
    say

    for cmd in "${commands[@]}"; do
        if has_cmd "$cmd"; then
            state="present"
            version="$(command_version "$cmd")"
            printf '[OK] %-16s %-8s %s\n' "$cmd" "$state" "$version"
        else
            state="missing"
            printf '[KO] %-16s %-8s %s\n' "$cmd" "$state" "run: ./wifi_air_suite.sh --install"
            rc=1
        fi
    done

    say

    [[ -d "$MYINFO_DIR" ]] \
        && ok "myinfo directory present: $MYINFO_DIR" \
        || { warn "myinfo directory missing: $MYINFO_DIR"; rc=1; }

    [[ -f "$EXCLUSION_FILE" ]] \
        && ok "exclusions file present: $EXCLUSION_FILE" \
        || { warn "exclusions file missing: $EXCLUSION_FILE"; rc=1; }

    [[ -f "$OUI_FILE" ]] \
        && ok "OUI file present: $OUI_FILE" \
        || warn "OUI file missing: $OUI_FILE (Manufacturer enrichment unavailable)"

    if [[ -x "$MONITOR_HELPER" ]]; then
        ok "monitor helper executable: $MONITOR_HELPER"
    else
        warn "monitor helper missing/non-executable: $MONITOR_HELPER"
        warn "Exact check: test -x \"$MONITOR_HELPER\" && echo OK || echo KO"
    fi

    say
    say "Detected Wi-Fi interfaces:"
    if has_cmd iw; then
        iw dev 2>/dev/null | awk '$1 == "Interface" { print "  " $2 }' || true
    else
        say "  iw unavailable"
    fi

    if (( rc != 0 )); then
        say
        say "Recommended exact command:"
        say "  ./wifi_air_suite.sh --install"
    fi

    return "$rc"
}

run_install() {
    local -a packages=(
        aircrack-ng
        util-linux
        iw
        wireless-tools
        network-manager
        coreutils
        findutils
        gawk
        sed
        grep
        curl
    )

    if (( SIMULATE_MODE == 1 )); then
        warn "SIMULATION: prerequisite installation not executed."
        printf 'Would run: run_privileged apt-get update && sudo apt-get install -y'
        printf ' %q' "${packages[@]}"
        printf '\n'
        return 0
    fi

    need_cmd sudo
    need_cmd apt-get
    sudo_ready

    info "Installing supported prerequisite package set."
    info "Command: run_privileged apt-get update"
    run_privileged apt-get update || die "APT update failed. Retry exactly: run_privileged apt-get update"

    info "Command: sudo apt-get install -y ${packages[*]}"
    run_privileged apt-get install -y "${packages[@]}" \
        || die "APT install failed. Retry exactly: sudo apt-get install -y ${packages[*]}"

    run_prerequis || true
}

update_oui_database() {
    local raw_file normalized_file final_file entry_count downloader updated_at

    ensure_dirs

    raw_file="$TMP_DIR/oui.ieee.raw.$$"
    normalized_file="$TMP_DIR/oui.normalized.$$"
    final_file="$MYINFO_DIR/.oui.txt.new.$$"

    if (( SIMULATE_MODE == 1 )); then
        warn "SIMULATION: OUI update not executed."
        say "Source      : $OUI_SOURCE_URL"
        say "Destination : $OUI_FILE"
        say "Backup      : $OUI_BACKUP_FILE"
        say "Validation  : IEEE '(hex)' entries >= $MIN_OUI_ENTRIES before replacement"
        return 0
    fi

    if has_cmd curl; then
        downloader="curl"
        info "OUI download         : curl"
        if ! curl -fsSL --show-error --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 180 \
            --user-agent "wifi_air_suite/$VERSION" \
            -o "$raw_file" "$OUI_SOURCE_URL"; then
            rm -f "$raw_file" "$normalized_file" "$final_file"
            die "Échec téléchargement OUI depuis : $OUI_SOURCE_URL"
        fi
    elif has_cmd wget; then
        downloader="wget"
        info "OUI download         : wget"
        if ! wget --https-only --timeout=30 --tries=3 \
            --user-agent="wifi_air_suite/$VERSION" \
            -O "$raw_file" "$OUI_SOURCE_URL"; then
            rm -f "$raw_file" "$normalized_file" "$final_file"
            die "Échec téléchargement OUI depuis : $OUI_SOURCE_URL"
        fi
    else
        die "--update-oui exige curl ou wget. Installe curl avec : ./wifi_air_suite.sh --install"
    fi

    [[ -s "$raw_file" ]] || {
        rm -f "$raw_file" "$normalized_file" "$final_file"
        die "Base OUI téléchargée vide : remplacement refusé."
    }

    # IEEE oui.txt contains MA-L lines shaped like:
    #   AA-BB-CC   (hex)        Organization Name
    # Normalize only those 24-bit OUI entries because enrich_csv() currently
    # performs manufacturer lookup on the first 24 bits of each MAC address.
    sed -nE 's/^([0-9A-Fa-f]{2})-([0-9A-Fa-f]{2})-([0-9A-Fa-f]{2})[[:space:]]+\(hex\)[[:space:]]+(.*)$/\1:\2:\3\t\4/p' \
        "$raw_file" > "$normalized_file"

    entry_count="$(wc -l < "$normalized_file" | tr -d '[:space:]')"
    entry_count="${entry_count:-0}"

    if [[ ! "$entry_count" =~ ^[0-9]+$ ]] || (( entry_count < MIN_OUI_ENTRIES )); then
        rm -f "$raw_file" "$normalized_file" "$final_file"
        die "Validation OUI refusée : seulement $entry_count entrées reconnues. L'ancien fichier est conservé."
    fi

    updated_at="$(date --iso-8601=seconds 2>/dev/null || date)"
    {
        echo "# wifi_air_suite OUI / IEEE MA-L database"
        echo "# Source: $OUI_SOURCE_URL"
        echo "# Updated: $updated_at"
        echo "# Entries: $entry_count"
        printf '# Format: AA:BB:CC<TAB>Manufacturer Name\n'
        cat "$normalized_file"
    } > "$final_file"

    if [[ -f "$OUI_FILE" ]]; then
        cp -f -- "$OUI_FILE" "$OUI_BACKUP_FILE" \
            || { rm -f "$raw_file" "$normalized_file" "$final_file"; die "Impossible de sauvegarder l'ancien OUI : $OUI_BACKUP_FILE"; }
    fi

    mv -f -- "$final_file" "$OUI_FILE" \
        || { rm -f "$raw_file" "$normalized_file" "$final_file"; die "Impossible d'installer la nouvelle base OUI."; }

    chmod 0644 "$OUI_FILE" 2>/dev/null || true
    rm -f "$raw_file" "$normalized_file"

    if (( EUID == 0 )) && [[ -n "${SUDO_USER:-}" ]] && id "$SUDO_USER" >/dev/null 2>&1; then
        chown "$SUDO_USER:$(id -gn "$SUDO_USER")" "$OUI_FILE" "$OUI_BACKUP_FILE" 2>/dev/null || true
    fi

    ok "Base OUI mise à jour : $OUI_FILE"
    ok "Entrées IEEE MA-L     : $entry_count"
    [[ -f "$OUI_BACKUP_FILE" ]] && info "Sauvegarde précédente : $OUI_BACKUP_FILE"
    info "Source               : $OUI_SOURCE_URL"
    info "Téléchargeur         : $downloader"
}

show_paths() {
    cat <<EOF
BASE_DIR=$BASE_DIR
PROJECT_ROOT=$PROJECT_ROOT
MONITOR_HELPER=$MONITOR_HELPER

MYINFO_DIR=$MYINFO_DIR
EXCLUSION_FILE=$EXCLUSION_FILE
OUI_FILE=$OUI_FILE
OUI_BACKUP_FILE=$OUI_BACKUP_FILE
OUI_SOURCE_URL=$OUI_SOURCE_URL

RUNTIME_DIR=$RUNTIME_DIR
CAP_DIR=$CAP_DIR
CSV_DIR=$CSV_DIR
FILTERED_DIR=$FILTERED_DIR
ENRICHED_DIR=$ENRICHED_DIR
GENERATED_DIR=$GENERATED_DIR
LOG_DIR=$LOG_DIR
TMP_DIR=$TMP_DIR
ARCHIVE_DIR=$ARCHIVE_DIR
PID_FILE=$PID_FILE
EOF
}

print_config() {
    cat <<EOF
VERSION=$VERSION
SCRIPT_DATE=$SCRIPT_DATE
ACTION=$ACTION
EXEC_MODE=$EXEC_MODE
SIMULATE_MODE=$SIMULATE_MODE
DRY_RUN=$DRY_RUN

REQUESTED_IFACE=$REQUESTED_IFACE
WLAN_IFACE=$WLAN_IFACE
BASE_WLAN_IFACE=$BASE_WLAN_IFACE

DURATION=$DURATION
INFINITE=$INFINITE
INTERVAL_MINUTES=$INTERVAL_MINUTES
POST_PROCESS=$POST_PROCESS
ACCEPT_MODE=$ACCEPT_MODE
OPEN_KATE=$OPEN_KATE
ARCHIVE_OLD=$ARCHIVE_OLD
SPINNER=$SPINNER
NO_LOG=$NO_LOG

OFFSET=$OFFSET
ALL_FILES=$ALL_FILES
CAP_FILE=$CAP_FILE
CSV_FILE=$CSV_FILE

BSSID_FILTER=$BSSID_FILTER
CHANNEL_FILTER=$CHANNEL_FILTER
STATION_FILTER=$STATION_FILTER
WORDLIST=$WORDLIST
DEAUTH_COUNT=$DEAUTH_COUNT

EXCLUSION_FILE=$EXCLUSION_FILE
OUI_FILE=$OUI_FILE
OUI_BACKUP_FILE=$OUI_BACKUP_FILE
OUI_SOURCE_URL=$OUI_SOURCE_URL
MIN_OUI_ENTRIES=$MIN_OUI_ENTRIES
RUNTIME_DIR=$RUNTIME_DIR
PID_FILE=$PID_FILE
EOF
}

doctor() {
    say "wifi_air_suite.sh $VERSION — DOCTOR"
    say
    show_paths
    say
    run_prerequis || true
    say
    say "Current iw dev:"
    if has_cmd iw; then
        iw dev 2>/dev/null || true
    else
        say "iw unavailable"
    fi
    say
    say "Current runtime tree:"
    find "$RUNTIME_DIR" -maxdepth 2 -type f 2>/dev/null | sort || true
}

init_layout() {
    ensure_dirs

    if [[ ! -f "$OUI_FILE" ]]; then
        : > "$OUI_FILE"
        warn "OUI file created empty: $OUI_FILE"
        warn "Replace it with a real oui.txt before using Manufacturer enrichment."
    fi

    runtime_chown || true

    ok "Layout initialized."
    show_paths
}

list_captures() {
    ensure_dirs
    info "CAP files:"
    ls -lh "$CAP_DIR"/*.cap 2>/dev/null || true
}

list_csv() {
    ensure_dirs
    info "CSV files:"
    ls -lh "$CAP_DIR"/*.csv "$CSV_DIR"/*.csv "$FILTERED_DIR"/*.csv "$ENRICHED_DIR"/*.csv 2>/dev/null || true
}

clean_tmp_action() {
    ensure_dirs
    clean_tmp_impl
    runtime_chown || true
    ok "tmp cleaned: $TMP_DIR"
}

purge_action() {
    if (( SIMULATE_MODE == 1 )); then
        warn "SIMULATION: purge not executed."
        say "Would remove runtime files only from:"
        say "  $CAP_DIR"
        say "  $CSV_DIR"
        say "  $FILTERED_DIR"
        say "  $ENRICHED_DIR"
        say "  $GENERATED_DIR"
        say "  $LOG_DIR"
        say "  $TMP_DIR"
        return 0
    fi

    clean_runtime_impl
    runtime_chown || true
    ok "Runtime purged: $RUNTIME_DIR"
    ok "myinfo preserved: $MYINFO_DIR"
}

register_runtime_pid() {
    ensure_dirs
    printf '%s %s %s\n' "$$" "$ACTION" "$(date --iso-8601=seconds 2>/dev/null || date)" > "$PID_FILE"
}

unregister_runtime_pid() {
    if [[ -f "$PID_FILE" ]]; then
        local registered_pid
        registered_pid="$(awk '{print $1}' "$PID_FILE" 2>/dev/null || true)"
        if [[ "$registered_pid" == "$$" ]]; then
            rm -f "$PID_FILE"
        fi
    fi
}

stop_action() {
    local pid action

    if [[ ! -f "$PID_FILE" ]]; then
        warn "No active runtime PID file: $PID_FILE"
        return 0
    fi

    pid="$(awk '{print $1}' "$PID_FILE" 2>/dev/null || true)"
    action="$(awk '{print $2}' "$PID_FILE" 2>/dev/null || true)"

    if [[ -z "$pid" || ! "$pid" =~ ^[0-9]+$ ]]; then
        warn "Invalid PID file; removing stale file: $PID_FILE"
        rm -f "$PID_FILE"
        return 1
    fi

    if ! kill -0 "$pid" 2>/dev/null; then
        warn "Stale PID $pid ($action); removing $PID_FILE"
        rm -f "$PID_FILE"
        return 0
    fi

    if (( SIMULATE_MODE == 1 )); then
        warn "SIMULATION: would send TERM to PID $pid ($action)."
        return 0
    fi

    info "Stopping PID $pid ($action) with TERM."
    kill -TERM "$pid" || die "Unable to stop PID $pid. Retry exactly: kill -TERM $pid"
    ok "TERM sent to PID $pid."
}

print_execution_summary() {
    local mode="$1"
    shift || true
    local index=1 item

    say
    say "EXECUTION SUMMARY:"
    for item in "$@"; do
        printf '  %d. [%s] %s\n' "$index" "$mode" "$item"
        ((index++))
    done
}

simulation_stop() {
    if (( SIMULATE_MODE == 1 )); then
        warn "SIMULATION: no privileged/system/network change will be performed."
        print_config

        case "$ACTION" in
            capture)
                print_execution_summary "SIMULATED" \
                    "Would resolve interface: $REQUESTED_IFACE" \
                    "Would capture with airodump-ng" \
                    "Would show the airodump-ng table live through a PTY when --spinner is not active" \
                    "Would use duration: ${DURATION:-INFINITE}" \
                    "Would use interval minutes: ${INTERVAL_MINUTES:-DISABLED}" \
                    "Would use BSSID filter: ${BSSID_FILTER:-DISABLED}" \
                    "Would use channel: ${CHANNEL_FILTER:-DEFAULT_MULTI_CHANNEL}" \
                    "Would post-process after each completed interval: $POST_PROCESS" \
                    "Would generate filtered Markdown during post-process: $POST_PROCESS" \
                    "Would open filtered Markdown in Kate: $OPEN_KATE" \
                    "Would accept non-interactive confirmations: $ACCEPT_MODE" \
                    "Would create persistent log files: $(( NO_LOG == 0 ? 1 : 0 ))" \
                    "Would never launch aircrack-ng from CAPTURE"
                ;;
            check)
                print_execution_summary "SIMULATED" \
                    "Would select CAP by --cap-file or offset $OFFSET" \
                    "Would inspect it with bounded non-interactive aircrack-ng"
                ;;
            crack)
                print_execution_summary "SIMULATED" \
                    "Would select CAP by --cap-file or offset $OFFSET" \
                    "Would require BSSID: ${BSSID_FILTER:-MISSING}" \
                    "Would require wordlist: ${WORDLIST:-MISSING}" \
                    "Would run explicit aircrack-ng crack action"
                ;;
            attack-hosts|attack-preauth|test-injection)
                print_execution_summary "SIMULATED" \
                    "Would resolve monitor interface: $REQUESTED_IFACE" \
                    "Would execute only the selected authorized/lab action: $ACTION"
                ;;
        esac

        exit 0
    fi
}

# ==============================================================================
# INTERFACE / MONITOR
# ==============================================================================

interface_exists() {
    iw dev "$1" info >/dev/null 2>&1
}

interface_type() {
    iw dev "$1" info 2>/dev/null | awk '$1 == "type" { print $2; exit }'
}

resolve_interface() {
    local requested="$1"
    local candidate

    REQUESTED_IFACE="$requested"
    BASE_WLAN_IFACE="$(derive_base_iface "$requested")"

    if interface_exists "$requested"; then
        WLAN_IFACE="$requested"
        return 0
    fi

    candidate="${BASE_WLAN_IFACE}mon"
    if interface_exists "$candidate"; then
        info "$requested absent ; monitor détecté : $candidate"
        WLAN_IFACE="$candidate"
        return 0
    fi

    err "Interface introuvable : $requested"
    iw dev 2>/dev/null | awk '$1 == "Interface" { print "  " $2 }' >&2 || true
    return 1
}

set_monitor_mode() {
    local typ

    resolve_interface "$REQUESTED_IFACE" || return 1
    typ="$(interface_type "$WLAN_IFACE")"

    if [[ "$typ" == "monitor" ]]; then
        info "Interface déjà en monitor : $WLAN_IFACE"
        MONITOR_CHANGED_BY_THIS_SCRIPT=0
    else
        if [[ ! -x "$MONITOR_HELPER" ]]; then
            err "Helper monitor absent/non exécutable : $MONITOR_HELPER"
            return 1
        fi

        if ! interface_exists "$BASE_WLAN_IFACE"; then
            err "Interface de base absente : $BASE_WLAN_IFACE"
            return 1
        fi

        info "Passage en monitor via helper : $MONITOR_HELPER"
        "$MONITOR_HELPER" "$BASE_WLAN_IFACE" set || return 1
        MONITOR_CHANGED_BY_THIS_SCRIPT=1

        if interface_exists "${BASE_WLAN_IFACE}mon"; then
            WLAN_IFACE="${BASE_WLAN_IFACE}mon"
        elif interface_exists "$BASE_WLAN_IFACE"; then
            WLAN_IFACE="$BASE_WLAN_IFACE"
        else
            err "Interface monitor introuvable après helper."
            return 1
        fi
    fi

    run_privileged iw reg set BE 2>/dev/null || true
    run_privileged iwconfig "$WLAN_IFACE" power off 2>/dev/null || true
}

set_managed_mode() {
    if (( MONITOR_CHANGED_BY_THIS_SCRIPT == 0 )); then
        info "Monitor préexistant/non modifié : état conservé."
        return 0
    fi

    if [[ ! -x "$MONITOR_HELPER" ]]; then
        warn "Helper monitor absent pour retour managed."
        return 1
    fi

    if interface_exists "$BASE_WLAN_IFACE"; then
        info "Retour managed via helper : $MONITOR_HELPER"
        "$MONITOR_HELPER" "$BASE_WLAN_IFACE" unset || return 1
        WLAN_IFACE="$BASE_WLAN_IFACE"
        MONITOR_CHANGED_BY_THIS_SCRIPT=0
        return 0
    fi

    warn "Interface base absente pour retour managed : $BASE_WLAN_IFACE"
    return 1
}

cleanup() {
    local rc=$?

    case "$ACTION" in
        capture|attack-hosts|attack-preauth|test-injection)
            echo
            info "Fin/interruption -> cleanup monitor/runtime."
            set_managed_mode || true
            unregister_runtime_pid || true
            runtime_chown || true
            ;;
    esac

    sudo_keepalive_stop || true
    exit "$rc"
}

trap cleanup INT TERM HUP
trap 'sudo_keepalive_stop || true' EXIT

# ==============================================================================
# CSV / EXCLUSIONS / OUI
# ==============================================================================

load_exclusions() {
    EXCLUSIONS=()

    [[ -f "$EXCLUSION_FILE" ]] || return 0

    mapfile -t EXCLUSIONS < <(
        grep -E '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' "$EXCLUSION_FILE" 2>/dev/null \
        | tr 'a-f' 'A-F' \
        | awk '{print $1}'
    )
}

selected_cap() {
    if [[ -n "$CAP_FILE" ]]; then
        [[ -f "$CAP_FILE" ]] || die "CAP introuvable : $CAP_FILE"
        printf '%s\n' "$CAP_FILE"
        return 0
    fi

    ls -1t "$CAP_DIR"/*.cap 2>/dev/null | sed -n "${OFFSET}p" || true
}

selected_csv_list() {
    if [[ -n "$CSV_FILE" ]]; then
        [[ -f "$CSV_FILE" ]] || die "CSV introuvable : $CSV_FILE"
        printf '%s\n' "$CSV_FILE"
        return 0
    fi

    if (( ALL_FILES == 1 )); then
        ls -1t "$CAP_DIR"/*.csv "$CSV_DIR"/*.csv 2>/dev/null || true
    else
        ls -1t "$CAP_DIR"/*.csv "$CSV_DIR"/*.csv 2>/dev/null | sed -n "${OFFSET}p" || true
    fi
}

latest_csv() {
    selected_csv_list | head -n 1
}

filter_csv() {
    local input="$1"
    local output="$2"

    load_exclusions

    awk -F',' -v excl="$(printf "%s\n" "${EXCLUSIONS[@]:-}")" '
        BEGIN {
            split(excl, lines, "\n")
            for (i in lines) {
                if (lines[i] != "") {
                    excluded[lines[i]] = 1
                }
            }
        }

        /^$/ {
            print
            next
        }

        NR == 1 || /Station MAC/ {
            print
            next
        }

        {
            first = toupper($1)
            sixth = toupper($6)

            if (!(first in excluded) && !(sixth in excluded)) {
                print
            }
        }
    ' "$input" > "$output"
}

enrich_csv() {
    local input="$1"
    local output="$2"

    [[ -f "$OUI_FILE" ]] || {
        warn "OUI absent : $OUI_FILE"
        return 1
    }

    awk -F',' -v oui_file="$OUI_FILE" '
        BEGIN {
            while ((getline line < oui_file) > 0) {
                gsub(/\r$/, "", line)
                if (line ~ /^[[:space:]]*$/) {
                    continue
                }

                key = ""
                value = ""

                split(line, tab, "\t")
                if (tab[1] != "" && tab[2] != "") {
                    key = tab[1]
                    value = tab[2]
                } else {
                    split(line, sp, /[[:space:]][[:space:]]+/)
                    key = sp[1]
                    value = sp[2]
                }

                key = toupper(key)
                gsub(/-/, ":", key)

                if (key ~ /^[0-9A-F]{6}$/) {
                    key = substr(key,1,2) ":" substr(key,3,2) ":" substr(key,5,2)
                }

                if (key ~ /^([0-9A-F]{2}:){2}[0-9A-F]{2}$/ && value != "") {
                    oui[key] = value
                }
            }
        }

        /^$/ {
            print
            next
        }

        /BSSID/ || /Station MAC/ {
            print $0 ",Manufacturer"
            next
        }

        {
            mac = toupper($1)
            pref = substr(mac,1,8)
            manuf = (pref in oui) ? oui[pref] : "Unknown"
            print $0 "," manuf
        }
    ' "$input" > "$output"
}

filtered_csv_to_markdown() {
    local input="$1"
    local output="$2"
    local source_name

    [[ -s "$input" ]] || {
        warn "CSV filtré vide/introuvable pour Markdown : $input"
        return 1
    }

    source_name="$(basename "$input")"

    awk -F',' -v source_name="$source_name" -v generated_at="$(date '+%Y-%m-%d %H:%M:%S')" '
        function trim(value) {
            gsub(/\r$/, "", value)
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        function cell(value) {
            value = trim(value)
            gsub(/\\/, "\\\\", value)
            gsub(/\|/, "\\|", value)
            return value
        }

        function print_row(    i) {
            printf "|"
            for (i = 1; i <= NF; i++) {
                printf " %s |", cell($i)
            }
            printf "\n"
        }

        function print_separator(    i) {
            printf "|"
            for (i = 1; i <= NF; i++) {
                printf " --- |"
            }
            printf "\n"
        }

        BEGIN {
            print "# Wi-Fi filtered results"
            print ""
            print "- Source: `" source_name "`"
            print "- Generated: " generated_at
            print ""
        }

        /^[[:space:]]*$/ { next }

        $1 ~ /^[[:space:]]*BSSID[[:space:]]*$/ {
            print "## Access Points"
            print ""
            print_row()
            print_separator()
            next
        }

        $1 ~ /^[[:space:]]*Station MAC[[:space:]]*$/ {
            print ""
            print "## Stations / Clients"
            print ""
            print_row()
            print_separator()
            next
        }

        { print_row() }
    ' "$input" > "$output"
}

open_markdown_in_kate() {
    local md_file="$1"

    (( OPEN_KATE == 1 )) || return 0

    if ! command -v kate >/dev/null 2>&1; then
        warn "--open-kate demandé mais Kate est introuvable dans PATH."
        return 1
    fi

    info "Ouverture Kate      : $md_file"
    kate "$md_file" >/dev/null 2>&1 &
    return 0
}

post_process() {
    local csv_in="$1"
    local base csv_copy filtered filtered_md enriched capfile

    [[ -s "$csv_in" ]] || {
        warn "CSV vide/introuvable pour post-process : $csv_in"
        return 1
    }

    base="$(basename "$csv_in")"
    csv_copy="$CSV_DIR/$base"
    filtered="$FILTERED_DIR/${base%.csv}.filtered.csv"
    filtered_md="$FILTERED_DIR/${base%.csv}.filtered.md"
    enriched="$ENRICHED_DIR/${base%.csv}.enriched.csv"

    cp -f "$csv_in" "$csv_copy"
    filter_csv "$csv_in" "$filtered"
    filtered_csv_to_markdown "$filtered" "$filtered_md" || true
    enrich_csv "$filtered" "$enriched" || true

    capfile="${csv_in%.csv}.cap"

    [[ -f "$capfile" ]] && cp -f "$capfile" "$GENERATED_DIR/" 2>/dev/null || true
    cp -f "$csv_copy" "$GENERATED_DIR/" 2>/dev/null || true
    cp -f "$filtered" "$GENERATED_DIR/" 2>/dev/null || true
    [[ -f "$filtered_md" ]] && cp -f "$filtered_md" "$GENERATED_DIR/" 2>/dev/null || true
    [[ -f "$enriched" ]] && cp -f "$enriched" "$GENERATED_DIR/" 2>/dev/null || true
    [[ -f "$GLOBAL_LOG_FILE" ]] && cp -f "$GLOBAL_LOG_FILE" "$GENERATED_DIR/" 2>/dev/null || true

    info "CSV brut copié  : $csv_copy"
    info "CSV filtré      : $filtered"
    [[ -f "$filtered_md" ]] && info "MD filtré       : $filtered_md"
    [[ -f "$enriched" ]] && info "CSV enrichi     : $enriched"
    info "Generated       : $GENERATED_DIR"

    [[ -f "$filtered_md" ]] && open_markdown_in_kate "$filtered_md" || true
}

show_latest_csv() {
    local csv
    csv="$(latest_csv || true)"

    [[ -n "$csv" && -s "$csv" ]] || {
        warn "Aucun CSV non vide à afficher."
        return 0
    }

    info "CSV : $csv"
    echo "---------------------------"
    filter_csv "$csv" "$TMP_DIR/display.filtered.csv"
    cat "$TMP_DIR/display.filtered.csv"
    echo "---------------------------"
}

extract_bssid_channels() {
    local csv="$1"

    awk -F',' '
        BEGIN { in_station=0 }

        /^Station MAC/ { in_station=1; next }

        !in_station && $1 ~ /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/ {
            bssid=toupper($1)
            ch=$4
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", ch)
            print bssid " " ch
        }
    ' "$csv"
}

extract_pairs() {
    local csv="$1"

    awk -F',' -v bssid_filter="$BSSID_FILTER" -v station_filter="$STATION_FILTER" '
        /^Station MAC/ { in_station=1; next }

        in_station && $1 ~ /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/ && $6 ~ /([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/ {
            station=toupper($1)
            bssid=toupper($6)
            gsub(/ /,"",station)
            gsub(/ /,"",bssid)

            if (bssid_filter != "" && bssid != bssid_filter) next
            if (station_filter != "" && station != station_filter) next

            print bssid " " station
        }
    ' "$csv"
}

# ==============================================================================
# CAPTURE
# ==============================================================================

build_airodump_cmd() {
    local -n arr=$1
    local capture_duration="${2:-}"

    arr=(
        airodump-ng
        "$WLAN_IFACE"
        --write "$CAP_DIR/${PREFIX}"
        --band abg
        --manufacturer
        --showack
        --beacons
        --uptime
        --wps
        --write-interval 5
        --update 1
        --output-format csv,pcap
    )

    if [[ -n "$CHANNEL_FILTER" ]]; then
        arr+=(--channel "$CHANNEL_FILTER")
    else
        arr+=(-c 1,2,3,4,5,6,7,8,9,10,11,12,13,14,36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,144,149,153,157,161,165)
    fi

    [[ -n "$BSSID_FILTER" ]] && arr+=(--bssid "$BSSID_FILTER")

    if [[ -n "$capture_duration" ]]; then
        arr=(
            timeout
            --foreground
            --signal=INT
            --kill-after=3s
            "${capture_duration}s"
            "${arr[@]}"
        )
    fi
}


shell_join_quoted() {
    local quoted=""
    printf -v quoted '%q ' "$@"
    printf '%s\n' "$quoted"
}

run_capture_live_with_pty() {
    local -a capture_cmd=("$@")
    local quoted_cmd rc

    if (( NO_LOG == 1 )); then
        info "Affichage live       : OUI (terminal direct)"
        info "Journal terminal     : DÉSACTIVÉ (--nolog)"

        # Without persistent logging there is no need to allocate a second PTY.
        # Running directly keeps airodump-ng attached to the user's real TTY,
        # so its full-screen AP/station table remains visible.
        run_privileged "${capture_cmd[@]}"
        rc=$?

        case "$rc" in
            0|124|130|137)
                return 0
                ;;
            *)
                warn "Direct capture returned code $rc."
                return "$rc"
                ;;
        esac
    fi

    quoted_cmd="$(shell_join_quoted "${capture_cmd[@]}")"

    info "Affichage live       : OUI (PTY)"
    info "Journal terminal     : $AIRODUMP_LOG_FILE"

    # airodump-ng is a full-screen TTY application. A normal pipe to `tee`
    # removes its terminal and can make the scan table appear blank. util-linux
    # `script` allocates a PTY, mirrors the screen live, and logs the same
    # terminal session with continuous flushing.
    run_privileged script -q -e -f -c "$quoted_cmd" "$AIRODUMP_LOG_FILE"
    rc=$?

    # Normal timed-capture exit codes:
    #   124 = GNU timeout reached duration
    #   130 = graceful SIGINT path
    #   137 = SIGKILL fallback after grace period
    case "$rc" in
        0|124|130|137)
            return 0
            ;;
        *)
            warn "PTY capture returned code $rc."
            return "$rc"
            ;;
    esac
}

spinner_wait() {
    local pid="$1"
    local chars='|/-\'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf '\rCapture en cours [%c] %s' "${chars:i%4:1}" "$(date '+%H:%M:%S')"
        sleep 0.25
        ((i++))
    done

    printf '\rCapture terminée à %s              \n' "$(date '+%H:%M:%S')"
}

run_capture_slice() {
    local slice_duration="${1:-}"
    local slice_index="${2:-1}"
    local slice_total="${3:-0}"
    local -a cmd
    local pid csv

    generate_prefix
    setup_logs

    if (( slice_total > 0 )); then
        info "Tranche             : ${slice_index}/${slice_total}"
    else
        info "Tranche             : ${slice_index} (boucle continue)"
    fi
    info "Préfixe            : $PREFIX"
    info "Durée tranche       : ${slice_duration:-INFINITE}"
    if (( NO_LOG == 1 )); then
        info "Log airodump       : DÉSACTIVÉ (--nolog)"
    else
        info "Log airodump       : $AIRODUMP_LOG_FILE"
    fi

    build_airodump_cmd cmd "$slice_duration"

    printf '%q ' "${cmd[@]}" >> "$GLOBAL_LOG_FILE"
    echo >> "$GLOBAL_LOG_FILE"

    if [[ -n "$slice_duration" && "$SPINNER" == "1" ]]; then
        info "Affichage live       : NON (--spinner actif)"
        run_privileged "${cmd[@]}" > "$AIRODUMP_LOG_FILE" 2>&1 &
        pid=$!
        spinner_wait "$pid"
        wait "$pid" || true
    else
        if ! run_capture_live_with_pty "${cmd[@]}"; then
            warn "PTY logging failed; retrying capture directly in the terminal."
            warn "Airodump log mirroring is disabled for this fallback run."
            run_privileged "${cmd[@]}" || true
        fi
    fi

    sync
    sleep 1

    csv="$CAP_DIR/${PREFIX}-01.csv"
    if [[ ! -s "$csv" ]]; then
        warn "CSV attendu absent/vide pour cette tranche : $csv"
        return 1
    fi

    if (( POST_PROCESS == 1 )); then
        info "Post-process tranche : démarrage"
        if post_process "$csv"; then
            ok "Post-process tranche terminé."
        else
            warn "Post-process tranche en erreur ; la capture suivante continuera."
        fi
    fi

    show_latest_csv
    runtime_chown || true
    return 0
}

run_capture() {
    local interval_seconds=0
    local remaining=0
    local slice_duration=""
    local slice_index=1
    local slice_total=1

    need_exec
    simulation_stop
    ensure_dirs
    capture_deps
    if (( OPEN_KATE == 1 )); then
        need_cmd kate
    fi
    sudo_ready
    auto_clean_tmp
    register_runtime_pid

    (( ARCHIVE_OLD == 1 )) && archive_old

    info "CAPTURE $VERSION"
    info "Interface demandée : $REQUESTED_IFACE"
    info "Runtime            : $RUNTIME_DIR"
    info "Durée totale       : ${DURATION:-INFINITE}"
    info "Intervalle         : ${INTERVAL_MINUTES:-DISABLED}${INTERVAL_MINUTES:+ minute(s)}"
    info "BSSID              : ${BSSID_FILTER:-DISABLED}"
    info "Canal              : ${CHANNEL_FILTER:-MULTI}"
    info "Post-process       : $POST_PROCESS"
    info "Open Kate          : $OPEN_KATE"
    info "Accept             : $ACCEPT_MODE"
    info "Logs persistants   : $(( NO_LOG == 0 ? 1 : 0 ))"

    if [[ -n "$INTERVAL_MINUTES" ]]; then
        interval_seconds=$(( INTERVAL_MINUTES * 60 ))
        if [[ -n "$DURATION" && "$INFINITE" != "1" ]]; then
            slice_total=$(( (DURATION + interval_seconds - 1) / interval_seconds ))
            info "Nombre de tranches : $slice_total"
        else
            slice_total=0
            info "Nombre de tranches : illimité (CTRL-C pour arrêter)"
        fi
    fi

    set_monitor_mode || die "Mode monitor impossible."

    info "Interface utilisée : $WLAN_IFACE"
    iwconfig "$WLAN_IFACE" || true

    if [[ -z "$INTERVAL_MINUTES" ]]; then
        if [[ -n "$DURATION" && "$INFINITE" != "1" ]]; then
            info "Arrêt timer         : SIGINT à ${DURATION}s, SIGKILL de secours +3s"
            slice_duration="$DURATION"
        else
            slice_duration=""
        fi
        run_capture_slice "$slice_duration" 1 1 || true
    elif [[ -n "$DURATION" && "$INFINITE" != "1" ]]; then
        remaining="$DURATION"
        while (( remaining > 0 )); do
            if (( remaining < interval_seconds )); then
                slice_duration="$remaining"
            else
                slice_duration="$interval_seconds"
            fi

            info "Arrêt tranche       : SIGINT à ${slice_duration}s, SIGKILL de secours +3s"
            run_capture_slice "$slice_duration" "$slice_index" "$slice_total" || true

            remaining=$(( remaining - slice_duration ))
            ((slice_index++))
        done
    else
        while :; do
            slice_duration="$interval_seconds"
            info "Arrêt tranche       : SIGINT à ${slice_duration}s, SIGKILL de secours +3s"
            run_capture_slice "$slice_duration" "$slice_index" 0 || true
            ((slice_index++))
        done
    fi

    set_managed_mode || true
    runtime_chown || true
    unregister_runtime_pid

    ok "CAPTURE terminée. Aucun aircrack-ng lancé."
    print_execution_summary "EXECUTED" \
        "Captured with airodump-ng only" \
        "Runtime root: $RUNTIME_DIR" \
        "Interval minutes: ${INTERVAL_MINUTES:-DISABLED}" \
        "BSSID filter: ${BSSID_FILTER:-DISABLED}" \
        "Channel: ${CHANNEL_FILTER:-DEFAULT_MULTI_CHANNEL}" \
        "Post-process enabled: $POST_PROCESS" \
        "Filtered Markdown: $POST_PROCESS" \
        "Open Kate: $OPEN_KATE" \
        "Accept mode: $ACCEPT_MODE" \
        "Persistent logs enabled: $(( NO_LOG == 0 ? 1 : 0 ))" \
        "aircrack-ng not launched from CAPTURE"
}

# ==============================================================================
# CHECK / CRACK
# ==============================================================================

run_check() {
    local cap rc

    need_exec
    simulation_stop
    ensure_dirs
    check_deps

    cap="$(selected_cap || true)"
    [[ -n "$cap" ]] || die "Aucun .cap trouvé."

    info "CHECK : $cap"
    info "Mode non interactif borné à 15 secondes."

    if [[ -n "$BSSID_FILTER" ]]; then
        timeout 15s aircrack-ng -b "$BSSID_FILTER" "$cap" </dev/null
        rc=$?
    else
        timeout 15s aircrack-ng "$cap" </dev/null
        rc=$?
    fi

    case "$rc" in
        0)
            ;;
        124)
            warn "CHECK timeout after 15s."
            warn "Retry exactly: ./wifi_air_suite.sh --exec --check --cap-file \"$cap\"${BSSID_FILTER:+ --bssid \"$BSSID_FILTER\"}"
            ;;
        *)
            warn "CHECK finished with return code: $rc"
            ;;
    esac

    print_execution_summary "EXECUTED" \
        "Selected capture: $cap" \
        "Ran bounded non-interactive CHECK" \
        "CAPTURE/CRACK/ATTACK were not triggered"
}

run_crack() {
    local cap

    need_exec
    simulation_stop
    ensure_dirs
    crack_deps

    [[ -n "$WORDLIST" ]] || die "--crack exige --wordlist FILE"
    [[ -f "$WORDLIST" ]] || die "Wordlist introuvable : $WORDLIST"
    [[ -n "$BSSID_FILTER" ]] || die "--crack exige --bssid MAC pour éviter toute sélection interactive."

    cap="$(selected_cap || true)"
    [[ -n "$cap" ]] || die "Aucun .cap trouvé."

    info "CRACK : $cap"
    info "BSSID : $BSSID_FILTER"
    info "Wordlist : $WORDLIST"

    aircrack-ng -w "$WORDLIST" -b "$BSSID_FILTER" "$cap"

    print_execution_summary "EXECUTED" \
        "Selected capture: $cap" \
        "Selected BSSID: $BSSID_FILTER" \
        "Ran explicit CRACK action" \
        "CAPTURE/CHECK/ATTACK were not triggered"
}
# ==============================================================================
# AUTHORIZED LAB ACTIONS
# ==============================================================================

attack_from_csv() {
    local mode="$1"
    local csv="$2"
    local filtered channels_file pairs_file line bssid station ch
    declare -A channel_by_bssid

    filtered="$TMP_DIR/$(basename "${csv%.csv}").attack.filtered.csv"
    channels_file="$TMP_DIR/$(basename "${csv%.csv}").channels.txt"
    pairs_file="$TMP_DIR/$(basename "${csv%.csv}").pairs.txt"

    filter_csv "$csv" "$filtered"
    extract_bssid_channels "$filtered" > "$channels_file"
    extract_pairs "$filtered" > "$pairs_file"

    while read -r bssid ch; do
        [[ -n "$bssid" ]] || continue
        channel_by_bssid["$bssid"]="$ch"
    done < "$channels_file"

    if [[ ! -s "$pairs_file" ]]; then
        warn "Aucune paire AP/station dans : $csv"
        return 0
    fi

    while read -r bssid station; do
        [[ -n "$bssid" && -n "$station" ]] || continue
        ch="${channel_by_bssid[$bssid]:-}"

        if [[ -z "$ch" || "$ch" == "-1" ]]; then
            warn "Canal inconnu pour $bssid -> skip"
            continue
        fi

        info "$mode : BSSID=$bssid STATION=$station CH=$ch"
        run_privileged iwconfig "$WLAN_IFACE" channel "$ch" 2>&1 | tee -a "$ACTION_LOG_FILE" || true

        case "$mode" in
            attack-hosts)
                run_privileged aireplay-ng --deauth "$DEAUTH_COUNT" -a "$bssid" -c "$station" "$WLAN_IFACE" --ignore-negative-one \
                    2>&1 | tee -a "$ACTION_LOG_FILE"
                ;;

            attack-preauth)
                run_privileged aireplay-ng --fakeauth 10 -a "$bssid" -h "$station" "$WLAN_IFACE" --ignore-negative-one \
                    2>&1 | tee -a "$ACTION_LOG_FILE"
                ;;
        esac
    done < "$pairs_file"
}

run_attack() {
    local mode="$1"
    local csv
    local -a csvs=()

    need_exec
    simulation_stop
    ensure_dirs
    attack_deps
    sudo_ready
    generate_prefix
    setup_logs
    register_runtime_pid

    set_monitor_mode || die "Mode monitor impossible."

    mapfile -t csvs < <(selected_csv_list)

    if [[ ${#csvs[@]} -eq 0 ]]; then
        set_managed_mode || true
        die "Aucun CSV trouvé."
    fi

    for csv in "${csvs[@]}"; do
        [[ -s "$csv" ]] || continue
        attack_from_csv "$mode" "$csv"
    done

    set_managed_mode || true
    unregister_runtime_pid
    runtime_chown || true
    ok "$mode terminé."
    print_execution_summary "EXECUTED"         "Executed authorized/lab action: $mode"         "Processed selected CSV set"         "Returned interface to managed when this script changed it"
}

run_test_injection() {
    need_exec
    simulation_stop
    ensure_dirs
    attack_deps
    sudo_ready
    generate_prefix
    setup_logs
    register_runtime_pid

    set_monitor_mode || die "Mode monitor impossible."

    info "TEST-INJECTION sur $WLAN_IFACE"
    run_privileged aireplay-ng --test "$WLAN_IFACE" 2>&1 | tee -a "$ACTION_LOG_FILE"

    set_managed_mode || true
    unregister_runtime_pid
    runtime_chown || true
    print_execution_summary "EXECUTED"         "Executed authorized/lab injection test"         "Returned interface to managed when this script changed it"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    parse_args "$@"

    case "$ACTION" in
        prerequis)
            run_prerequis
            ;;

        install)
            run_install
            ;;

        stop)
            stop_action
            ;;

        purge)
            purge_action
            ;;

        doctor)
            doctor
            ;;

        init)
            init_layout
            ;;

        show-paths)
            show_paths
            ;;

        print-config)
            print_config
            ;;

        list-captures)
            list_captures
            ;;

        list-csv)
            list_csv
            ;;

        clean-tmp)
            clean_tmp_action
            ;;

        update-oui)
            update_oui_database
            ;;

        capture)
            run_capture
            ;;

        check)
            run_check
            ;;

        crack)
            run_crack
            ;;

        attack-hosts)
            run_attack "attack-hosts"
            ;;

        attack-preauth)
            run_attack "attack-preauth"
            ;;

        test-injection)
            run_test_injection
            ;;

        *)
            die "Action inconnue : $ACTION"
            ;;
    esac
}
main "$@"


# ==============================================================================
# v1.0.10 TIMED CAPTURE IMPLEMENTATION NOTE
# ==============================================================================
# GNU timeout sends SIGTERM by default. airodump-ng can remain alive after that
# signal in an interactive/monitor-mode capture, which can leave the wrapper
# waiting beyond the requested --duration.
#
# Timed capture therefore uses:
#
#   timeout --foreground --signal=INT --kill-after=3s DURATIONs airodump-ng ...
#
# Rationale:
# - --foreground keeps the child attached appropriately to the terminal context.
# - SIGINT matches the normal interactive airodump-ng shutdown path and gives it
#   a chance to close/flush capture files cleanly.
# - --kill-after=3s guarantees a hard upper bound if graceful shutdown fails.
# - CAPTURE remains capture-only; no CHECK/CRACK/ATTACK action is chained.
#
# Expected timing:
# - normal case: process exits around DURATION seconds;
# - fallback case: process is forcibly ended no later than about DURATION + 3s,
#   excluding unrelated setup/cleanup time before or after airodump-ng itself.
# ==============================================================================


# ==============================================================================
# v1.0.11 LIVE AIRODUMP DISPLAY IMPLEMENTATION NOTE
# ==============================================================================
# airodump-ng is an interactive full-screen terminal application. Its display
# uses cursor movement and terminal control sequences. Sending its output
# through:
#
#   airodump-ng ... 2>&1 | tee logfile
#
# means airodump-ng no longer sees a TTY. Capture may still work, but the user
# can see only a creation message followed by blank-looking terminal output.
#
# v1.0.11 keeps the capture action, duration watchdog and post-processing, but
# changes the default visible transport to:
#
#   script -q -e -f -c "<quoted capture command>" "$AIRODUMP_LOG_FILE"
#
# The util-linux `script` command provides a pseudo-terminal:
# - airodump-ng sees a terminal and renders its normal AP/station table;
# - the real terminal receives the live screen;
# - the same session is written to the log;
# - -f flushes the log continuously;
# - -e returns the child command exit status.
#
# `--spinner` deliberately remains a different mode: it hides the full airodump
# screen and shows only the spinner while writing raw command output to the log.
#
# No wireless capability is added here. CAPTURE/CHECK/CRACK separation, monitor
# helper behavior, exclusions, OUI enrichment, timeout behavior and .results/
# layout are preserved.
# ==============================================================================
# ==============================================================================
# v1.0.12 INTERNAL SUDO AUTHENTICATION IMPLEMENTATION NOTE\n# ==============================================================================\n# Intended invocation:\n#\n#   ./wifi_air_suite.sh --exec --capture ...\n#\n# External `sudo ./wifi_air_suite.sh ...` remains supported but is not required.\n#\n# Authentication sequence:\n# 1. EUID=0 -> no sudo prompt.\n# 2. Existing ticket -> validate with `sudo -n -v`.\n# 3. No ticket -> run `sudo -v` explicitly on /dev/tty.\n# 4. Verify the ticket with `sudo -n -v`.\n# 5. Refresh the valid ticket every 45 seconds for long operations.\n# 6. Run all later privileged children with `sudo -n`.\n# 7. Stop the keepalive at process exit or signal cleanup.\n#\n# wifi_air_suite.sh never reads, stores, logs or echoes the password itself.\n# Password handling remains entirely inside sudo on the controlling terminal.\n# ==============================================================================\n

# ==============================================================================
# v1.0.13 SUDO CORRECTION NOTE
# ==============================================================================
# Target-host evidence showed that the v1.0.12 authentication path:
#
#   sudo -v ... </dev/tty >/dev/tty
#
# displayed a password prompt but then immediately failed with:
#
#   sudo: password is required
#
# v1.0.13 therefore returns to sudo's native terminal handling:
#
#   sudo -v -p "[sudo] Mot de passe de %u : "
#
# sudo itself opens the controlling terminal as designed. No password is read or
# stored by wifi_air_suite.sh.
#
# The second structural fix is PTY-related. If sudo uses tty-scoped timestamps,
# running `sudo -n airodump-ng` INSIDE the PTY created by `script` can be seen as
# a different terminal from the one where the user authenticated.
#
# v1.0.13 removes sudo from the airodump command array and instead runs:
#
#   run_privileged script -q -e -f -c "<timeout/airodump command>" logfile
#
# Elevation therefore occurs before `script` creates the child PTY. airodump-ng
# inherits root privileges inside the PTY without running another sudo command.
#
# This preserves:
# - live airodump display;
# - timed stop at DURATION (+3s hard fallback);
# - CAPTURE/CHECK/CRACK separation;
# - existing monitor helper behavior;
# - CSV/OUI post-processing and exclusions;
# - .results runtime layout.
# ==============================================================================


# ==============================================================================
# v2.1.0 FILTERED MARKDOWN / KATE IMPLEMENTATION NOTE
# ==============================================================================
# When --post-process is active, the already-filtered CSV is converted to a
# Markdown file in the same filtered directory:
#
#   .results/filtered/<prefix>-01.filtered.csv
#   .results/filtered/<prefix>-01.filtered.md
#
# The Markdown conversion does not re-run exclusion decisions. It consumes the
# filtered CSV produced by filter_csv(), so CSV and Markdown represent the same
# filtered dataset. Access-point and station sections are rendered as Markdown
# tables. The Markdown file is also copied to .results/generated/.
#
# --open-kate is optional and requires --post-process. When enabled, each newly
# created filtered Markdown file is sent to Kate asynchronously. The capture
# loop never waits for the editor to close before starting the next interval.
# ==============================================================================

# ==============================================================================
# v2.0.0 INTERVAL CAPTURE IMPLEMENTATION NOTE
# ==============================================================================
# --duration remains seconds. --interval is minutes.
#
# Example:
#   --duration 3600 --interval 10 --post-process --accept
#
# The overall monitor-mode session stays active while airodump-ng is restarted
# at each interval boundary. Every interval receives a fresh collision-safe
# PREFIX generated by the existing generate_prefix() function, therefore normal
# files remain in the same directories and keep the same -01.csv / -01.cap form.
#
# When --post-process is enabled, each completed interval is processed before
# the next interval begins. A post-process error is logged/warned but does not
# abort the remaining capture intervals.
#
# --accept is parsed for CLI compatibility and future non-interactive gates. It
# does not and must not bypass sudo authentication.
# ==============================================================================


# ==============================================================================
# v2.1.1 LOCAL MONITOR HELPER IMPLEMENTATION NOTE
# ==============================================================================
# The public repository now keeps set_unset_to_monitor.sh beside
# wifi_air_suite.sh. BASE_DIR is therefore the canonical repository/runtime
# source directory and the helper path is resolved as:
#
#   MONITOR_HELPER="$BASE_DIR/set_unset_to_monitor.sh"
#
# No fallback to the historical tools/monitor/ path is used. A missing or
# non-executable helper is reported by the existing prerequisite/monitor checks.
# ==============================================================================

# ==============================================================================
# v2.1.2 --nolog IMPLEMENTATION NOTE
# ==============================================================================
# --nolog (alias --no-log) disables persistent runtime log files without
# disabling capture/result files.
#
# Behavior:
# - setup_logs() points all log sinks to /dev/null and creates no .log file.
# - Normal live CAPTURE runs the timeout/airodump command directly on the real
#   terminal, preserving the full-screen table without util-linux `script`.
# - --spinner continues to hide the airodump screen, but its output goes to
#   /dev/null instead of an airodump log.
# - attack/test actions keep terminal output through tee, with /dev/null as the
#   sink, so no ACTION_LOG_FILE is persisted.
# - CAP, CSV, filtered, enriched, generated and Markdown outputs are unchanged.
#
# Without --nolog, the v2.1.1 logging behavior is preserved exactly.
# ==============================================================================

# ==============================================================================
# v2.1.3 --update-oui IMPLEMENTATION NOTE
# ==============================================================================
# --update-oui refreshes myinfo/oui.txt from the IEEE Registration Authority
# MA-L/OUI public text listing.
#
# Safety/consistency rules:
# - no --exec gate is required because this is a local maintenance action;
# - download happens in .results/tmp first;
# - the raw source must produce at least MIN_OUI_ENTRIES valid IEEE '(hex)' rows;
# - normalization produces AA:BB:CC<TAB>Manufacturer entries for enrich_csv();
# - the previous database is copied to myinfo/oui.txt.bak;
# - replacement occurs only after validation and uses mv for an atomic local
#   handoff on the same filesystem;
# - failed download or validation leaves the current oui.txt untouched;
# - curl is preferred, wget is an accepted fallback;
# - WIFI_AIR_SUITE_OUI_URL can override the source for testing or a mirror.
# ==============================================================================

