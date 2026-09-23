# wifi_air_suite — Changelog

Canonical version: **v3.0.0**

The entries below are taken from the append-only changelog embedded in `wifi_air_suite.sh`.

```text
v3.0.0 - 2026-09-23 23:37 - Bruno DELNOZ
  MAJOR:
  - Establishes a clean v3 baseline from the validated v2.1.4 implementation.
  - Consolidates the complete documentation set and Product Guide for the current CLI.
  PRESERVED:
  - No hidden behavioral rewrite: v2.1.4 operational semantics are preserved.
  - --channel N remains capture-only, requires --bssid, and narrows a targeted capture to one supported channel.
  - --nolog, --update-oui, interval capture, post-processing, Kate integration, exclusions, and action separation remain unchanged.

v2.1.4 - 2026-09-23 23:37 - Bruno DELNOZ
  ADDED:
  - --channel N for targeted CAPTURE of a specific BSSID on one Wi-Fi channel.
  - --channel is validated against the channel set already supported by the capture engine.
  - --channel requires --capture and --bssid.
  CHANGED:
  - With --channel, airodump-ng receives one explicit channel instead of the default multi-channel list.
  PRESERVED:
  - Without --channel, capture behavior is unchanged.
  - --nolog, --post-process, interval capture and --update-oui are unchanged.

v2.1.3 - 2026-09-23 08:10 - Bruno DELNOZ
  ADDED:
  - --update-oui refreshes myinfo/oui.txt from the IEEE Registration Authority
    public MA-L/OUI listing.
  - The update is downloaded to runtime tmp storage, validated, normalized to
    AA:BB:CC<TAB>Manufacturer format, then atomically installed.
  - Existing myinfo/oui.txt is copied to myinfo/oui.txt.bak before replacement.
  - curl is preferred for download; wget is accepted as a fallback.
  - WIFI_AIR_SUITE_OUI_URL can override the source URL for testing/mirrors.
  PRESERVED:
  - Failed downloads/validation never overwrite the current OUI database.
  - --nolog behavior and all v2.1.2 capture/action behavior are unchanged.

v2.1.2 - 2026-09-22 00:31 - Bruno DELNOZ
  ADDED:
  - --nolog (alias --no-log) disables persistent runtime log files.
  - In CAPTURE live mode, --nolog runs airodump-ng directly on the current
    terminal instead of the util-linux script PTY logger, preserving the live
    table without creating airodump-*.log files.
  - In spinner and authorized/lab action modes, log sinks are redirected to
    /dev/null while terminal output remains available where applicable.
  CHANGED:
  - setup_logs() no longer creates GLOBAL/ACTION/AIRODUMP log files when
    --nolog is active.
  - post-process keeps CAP/CSV/filtered/enriched/generated outputs unchanged
    and simply has no global log file to copy when --nolog is active.
  PRESERVED:
  - Default behavior without --nolog remains unchanged.
  - Capture/check/crack/action separation, interval capture, --post-process,
    --open-kate, --accept, runtime layout and monitor handling are preserved.

v2.1.1 - 2026-09-16 03:05 - Bruno DELNOZ
  CHANGED:
  - set_unset_to_monitor.sh is now resolved from the same directory as
    wifi_air_suite.sh instead of PROJECT_ROOT/tools/monitor/.
  - PROJECT_ROOT now equals BASE_DIR because the public repository root is the
    directory that contains wifi_air_suite.sh and set_unset_to_monitor.sh.
  PRESERVED:
  - v2.1.0 filtered Markdown generation, --open-kate, interval capture,
    --post-process, --accept, runtime layout and all business actions.

v2.1.0 - 2026-09-16 02:57 - Bruno DELNOZ
  ADDED:
  - Generates a Markdown equivalent of each filtered CSV during --post-process.
    The file is stored beside the CSV as *.filtered.md in .results/filtered/.
  - --open-kate opens each newly generated filtered Markdown file in Kate.
    Kate is started asynchronously so capture intervals continue immediately.
  - The filtered Markdown contains separate Access Points and Stations / Clients
    tables generated from the already-filtered CSV; filtering logic is not duplicated.
  CHANGED:
  - Generated filtered Markdown files are also copied to .results/generated/.
  - --open-kate requires --post-process and is valid only with --capture.
  PRESERVED:
  - Existing filtered CSV, enriched CSV, CAP/CSV naming, interval behavior,
    --accept semantics, directories and behavior without --open-kate.

v2.0.0 - 2026-09-16 02:30 - Bruno DELNOZ
  MAJOR:
  - Adds interval-based CAPTURE sessions while preserving the existing CLI,
    runtime layout, naming scheme and capture/check/crack separation.
  ADDED:
  - --interval MINUTES for CAPTURE. Each interval is a complete independent
    airodump-ng slice with its own unique PREFIX and normal -01 CSV/CAP files.
  - --accept compatibility option for non-interactive acceptance semantics.
    The current capture flow has no confirmation prompt to auto-answer; sudo
    authentication remains handled by sudo and is never bypassed by --accept.
  - Per-interval post-processing: when --post-process is enabled, each finished
    interval is copied/filtered/OUI-enriched before the next interval starts.
  - Finite duration remainder support: if --duration is not exactly divisible
    by the interval length, the final slice uses the remaining seconds.
  - Infinite interval mode: --infinite --interval N (or no --duration with
    --interval N) repeats N-minute slices until interruption.
  CHANGED:
  - --duration remains expressed in SECONDS for backward compatibility.
  - --interval is expressed in MINUTES as requested for human-friendly loops.
  - Monitor mode is entered once for the whole capture session and preserved
    between slices; only airodump-ng is stopped/restarted at each boundary.
  - --archive-old still runs once, before the first slice only.
  PRESERVED:
  - Existing .results/{cap,csv,filtered,enriched,generated,logs,tmp,archive}
    layout and timestamp/collision-safe prefix generation.
  - Existing --post-process output formats and filenames.
  - Existing behavior when --interval is omitted.

v1.0.13-SOLO414 - 2026-09-15 20:43 - Bruno DELNOZ
  FIXED:
  - Reworked internal sudo authentication after the v1.0.12 /dev/tty flow
    still failed on the target Kali host with "password is required".
  - `sudo -v` now runs normally on the inherited controlling terminal instead
    of redirecting stdin/stdout through /dev/tty.
  - The post-authentication check now uses `sudo -n true` on the same terminal.
  - airodump-ng no longer executes an inner sudo from the PTY created by
    util-linux `script`; this avoids tty-bound sudo timestamp mismatches.
  ADDED:
  - run_privileged() wrapper: root executes directly, normal user executes
    through the already validated `sudo -n` ticket.
  CHANGED:
  - Timed/infinite airodump command arrays are now sudo-free.
  - The outer `script` PTY wrapper is elevated instead of the command inside
    the PTY, preserving the live airodump display without a second sudo prompt.

v1.0.12-SOLO414 - 2026-09-15 20:35 - Bruno DELNOZ
  FIXED:
  - Internal sudo authentication no longer depends on the script stdin stream.
  - When sudo credentials are not already cached, authentication is performed
    explicitly through /dev/tty with `sudo -v`.
  - Prevents the observed immediate `sudo: ... password is required` failure
    when the script is started normally without external `sudo`.
  ADDED:
  - Root detection: no sudo authentication prompt when EUID=0.
  - Sudo timestamp keepalive for long captures/attacks.
  - Automatic keepalive cleanup on EXIT, INT, TERM and HUP.
  - Explicit verification of the sudo ticket after interactive validation.
  CHANGED:
  - Privileged child commands use `sudo -n` after one-time authentication,
    so capture PTYs/logging never receive an unexpected password prompt.
  - --install now uses the same validated internal sudo path.

v1.0.11-SOLO414 - 2026-09-15 20:24 - Bruno DELNOZ
  FIXED:
  - Restores the live airodump-ng terminal display during CAPTURE.
  - Replaces the normal `2>&1 | tee` capture path with a pseudo-terminal
    provided by util-linux `script`, because piping airodump-ng through tee
    removes its TTY and its full-screen display can disappear/turn blank.
  - Keeps the airodump session logged while preserving the interactive screen.
  ADDED:
  - `script` command as an explicit CAPTURE prerequisite.
  - `util-linux` in the automated prerequisite installation package set.
  - A direct fallback to normal terminal execution if PTY logging fails.
  CHANGED:
  - Default non-spinner capture now runs inside a PTY and remains visible live.
  - Spinner mode still intentionally hides the airodump full-screen UI and
    shows only the spinner.

v1.0.10-SOLO414 - 2026-09-15 20:18 - Bruno DELNOZ
  FIXED:
  - Timed CAPTURE now stops reliably when --duration/-d is reached.
  - Replaced plain `timeout DURATION` with a foreground timeout using SIGINT
    for graceful airodump-ng shutdown and a hard SIGKILL fallback after 3s.
  - Prevents airodump-ng from remaining alive indefinitely when it does not
    terminate on GNU timeout's default SIGTERM.
  - Preserves CAP/CSV flush opportunity by sending SIGINT before the hard kill.
  CHANGED:
  - Timed capture command now uses:
      timeout --foreground --signal=INT --kill-after=3s <duration>s ...
  - Help now documents the bounded graceful-shutdown window for timed capture.

v1.0.9-SOLO414 - 2026-09-14 07:09 - Bruno DELNOZ
  ADDED:
  - Canonical SOLO control aliases: --exec/-exe, --simulate/-s,
    --prerequis/-pr, --install/-i, --stop/-st, --purge/-pu.
  - --dest_dir / --dest-dir to override the default .results runtime root.
  - Bounded non-interactive CHECK execution with timeout and stdin closed.
  - Runtime PID file so --stop can stop an active invocation started by this script.
  - Prerequisite version detection and exact installation recommendation.
  - Post-execution numbered summaries and explicit simulation summaries.
  CHANGED:
  - Canonical real execution is now --exec --<business-action>.
  - Canonical simulation is now --simulate --<business-action>, without --exec.
  - Historical --dry-run is retained as a compatibility alias for --simulate.
  - Historical --prereq/--check-prereq aliases are retained and mapped to --prerequis.
  - Historical --clean-runtime is retained and mapped to --purge.
  - --interface remains available only in long form because -i is reserved by --install.
  - --station remains available only in long form because -s is reserved by --simulate.
  - Positional business actions and positional interface syntax are removed from the parser.
  FIXED:
  - CAPTURE remains capture-only and never launches aircrack-ng.
  - CHECK and CRACK remain separate explicit business actions.
  - Simulation no longer requires --exec.
  - Help/parser/examples are aligned on one canonical CLI.
  - Header date now includes time.
  REMOVED:
  - Legacy positional CAPTURE/ATTACK/DONE/NODONE/NORMAL action tokens.
  - Conflicting historical short aliases -i for --interface and -s for --station.

v1.0.8-SOLO413 - 2026-09-14 - Bruno DELNOZ
  - Rebuilt script around canonical SOLO413-style CLI.
  - Uses --exec --capture / --exec --check / --exec --crack.
  - Keeps --exec gate mandatory for operational actions.
  - Keeps info/maintenance commands executable without --exec.
  - Adds --prereq, --check-prereq, --doctor, --init, --show-paths.
  - Adds --dry-run for operational actions.
  - Adds --clean-tmp and --clean-runtime.
  - Adds --version.
  - Keeps -X / --exclusions-file.
  - Keeps .results/ runtime tree.
  - CAPTURE never launches aircrack-ng.
  - CHECK/CRACK are separate explicit actions.
  - Keeps generated package as script-only ZIP.

v1.0.7 - 2026-09-14
  - Added missing prereq/doctor/control arguments.

v1.0.6 - 2026-09-14
  - First rebuilt --exec + separated action CLI.

v1.0.5 - 2026-09-14
  - Removed automatic aircrack-ng from CAPTURE.

v1.0.4 - 2026-09-14
  - Clean runtime moved under .results/.

v1.0.2 - 2026-09-14
  - Integrated useful bof.sh functions.

v1.0.1 - 2026-09-14
  - Delegated monitor/managed to tools/monitor/set_unset_to_monitor.sh.

v1.0.0 - 2026-09-14
  - Initial merged version from all.sh / all_woeking2.sh / all_working.sh.
```
