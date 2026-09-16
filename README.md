<!--
DOCUMENT INFORMATION
Document Name: README.md
Author: Bruno DELNOZ
Email: bruno.delnoz@protonmail.com
Version: v2.1.1
Date / Time: 2026-09-16 03:05
Project: Package scan WIFI / wifi_air_suite.sh
Short description: Project overview, canonical CLI, interval capture workflow, runtime layout and usage.
-->
# wifi_air_suite.sh — v2.1.1

## Purpose

`wifi_air_suite.sh` is the durable CLI entry point for the Wi-Fi capture package.

The operational filename remains exactly:

```text
wifi_air_suite.sh
```

Version **v2.1.1** keeps the v2.1.0 filtered-Markdown/Kate behavior and adapts the repository layout so the monitor helper lives directly beside the main script.

## Main v2.1.1 change

The public repository now uses this canonical root layout:

```text
wifi_air_suite/
├── wifi_air_suite.sh
├── set_unset_to_monitor.sh
├── README.md
├── INSTALL.md
├── CHANGELOG.md
├── WHY.md
├── SPECIFICATIONS.md
├── SPECIFICATIONS_FR.md
├── SPECIFICATIONS_GLOBAL.md
├── SPECIFICATIONS_GLOBAL_FR.md
├── myinfo/
└── .results/
```

`wifi_air_suite.sh` resolves the helper with:

```text
$BASE_DIR/set_unset_to_monitor.sh
```

The historical `tools/monitor/set_unset_to_monitor.sh` location is no longer used.

## Main v2.1.0 feature

When `--post-process` is enabled, every filtered CSV now also produces a Markdown equivalent in the same `filtered/` directory.

Example:

```text
.results/filtered/20260916_025700_1-01.filtered.csv
.results/filtered/20260916_025700_1-01.filtered.md
```

The Markdown file is generated from the already-filtered CSV, so exclusion logic is applied only once. It contains separate **Access Points** and **Stations / Clients** Markdown tables.

To open each new Markdown file automatically in Kate:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 --post-process --open-kate --accept
```

`--open-kate` is asynchronous: the next capture interval starts without waiting for Kate to close. It requires `--post-process`.

## Main v2.0.0 feature

A long capture can now be split into independent capture slices.

Example:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0   --duration 3600   --interval 10   --post-process   --accept
```

Interpretation:

- `--duration 3600` = total session duration of 3600 seconds;
- `--interval 10` = one capture slice every 10 minutes;
- six independent 600-second capture slices are executed;
- every slice gets a new collision-safe timestamp prefix;
- every slice writes its own normal `-01.csv` and `-01.cap`;
- with `--post-process`, every completed slice is copied, filtered and OUI-enriched before the next slice starts;
- `--accept` is accepted as a non-interactive compatibility flag and never bypasses sudo authentication.

If the total duration is not divisible by the interval, the final slice uses the remaining seconds.

Example:

```text
--duration 1250 --interval 10
```

produces:

```text
600 seconds
600 seconds
50 seconds
```

Without a finite duration:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0   --infinite --interval 10 --post-process --accept
```

the script repeats 10-minute slices until interruption.

## Action separation

| Action | Responsibility | Never triggered implicitly |
|---|---|---|
| `--capture` | `airodump-ng` capture, optional interval slicing and CSV post-processing | CHECK, CRACK, ATTACK |
| `--check` | bounded non-interactive inspection of a selected/latest CAP | CAPTURE, CRACK, ATTACK |
| `--crack` | explicit `aircrack-ng` wordlist action | CAPTURE, CHECK, ATTACK |
| `--attack-hosts` | authorized/lab deauthentication action from CSV pairs | CAPTURE, CRACK |
| `--attack-preauth` | authorized/lab fake-authentication action from CSV pairs | CAPTURE, CRACK |
| `--test-injection` | authorized/lab injection test | CAPTURE, CRACK |

CAPTURE remains strictly capture-only and never launches `aircrack-ng`.

## Canonical execution model

Real execution:

```bash
./wifi_air_suite.sh --exec --capture [OPTIONS]
./wifi_air_suite.sh --exec --check [OPTIONS]
./wifi_air_suite.sh --exec --crack [OPTIONS]
./wifi_air_suite.sh --exec --attack-hosts [OPTIONS]
./wifi_air_suite.sh --exec --attack-preauth [OPTIONS]
./wifi_air_suite.sh --exec --test-injection [OPTIONS]
```

Simulation:

```bash
./wifi_air_suite.sh --simulate --capture [OPTIONS]
./wifi_air_suite.sh --simulate --check [OPTIONS]
./wifi_air_suite.sh --simulate --crack [OPTIONS]
```

`--simulate` does not require `--exec`.

## Important capture options

```text
--interface IFACE
-d, --duration SECONDS
--infinite
--interval MINUTES
--post-process
--no-post-process
--accept
--archive-old
--spinner
--no-spinner
-X, --exclusions-file FILE
--dest_dir DIR
--dest-dir DIR
```

### Duration and interval units

The two units are intentionally different for compatibility:

```text
--duration = SECONDS
--interval = MINUTES
```

Existing commands using `--duration` therefore keep their previous meaning.

## Runtime layout

Default:

```text
wifi_air_suite/
├── wifi_air_suite.sh
├── set_unset_to_monitor.sh
├── myinfo/
│   ├── exclusions.txt
│   └── oui.txt
└── .results/
    ├── cap/
    ├── csv/
    ├── filtered/
    ├── enriched/
    ├── generated/
    ├── logs/
    ├── tmp/
    └── archive/
```

### Result meaning

- `.results/cap/` — raw `airodump-ng` CAP and CSV outputs;
- `.results/csv/` — copied raw CSV created by post-processing;
- `.results/filtered/` — CSV after MAC exclusions are applied;
- `.results/enriched/` — filtered CSV with manufacturer/OUI column when `myinfo/oui.txt` is available;
- `.results/generated/` — convenient generated copies of current processed artifacts;
- `.results/logs/` — session and airodump terminal logs;
- `.results/tmp/` — temporary runtime files and PID file;
- `.results/archive/` — archived older runtime results when `--archive-old` is requested.

The runtime root can be changed with `--dest_dir` / `--dest-dir`.

## Post-processing per interval

With:

```text
--interval N --post-process
```

the sequence for each slice is:

```text
start airodump-ng
→ stop/finalize current slice
→ verify the expected CSV
→ copy raw CSV
→ filter exclusions
→ OUI enrichment
→ copy generated artifacts
→ start next slice
```

A post-processing error emits a warning but does not abort the remaining capture slices.

## `--accept`

`--accept` is recognized by the v2 parser for non-interactive acceptance compatibility.

The current capture flow contains no confirmation prompt that needs automatic answering, so the flag is presently state/configuration compatibility rather than a sudo bypass. Sudo authentication still behaves normally and independently.

## Timed stop behavior

Every timed slice uses the established bounded shutdown path:

```text
SIGINT at requested duration
SIGKILL fallback after 3 additional seconds only if necessary
```

This preserves the opportunity for `airodump-ng` to flush CAP/CSV output.

## Live display

Default non-spinner capture uses the util-linux `script` command to provide a pseudo-terminal.

This keeps the live `airodump-ng` AP/station table visible while logging the terminal session.

`--spinner` intentionally hides the full-screen airodump display.

## Prerequisites

Check:

```bash
./wifi_air_suite.sh --prerequis
```

Install the supported package set:

```bash
./wifi_air_suite.sh --install
```

## Useful examples

20-second single capture:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 --duration 20 --post-process
```

One-hour capture split every ten minutes:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0   --duration 3600 --interval 10 --post-process --accept
```

Continuous ten-minute rolling captures:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0   --infinite --interval 10 --post-process --accept
```

Simulation:

```bash
./wifi_air_suite.sh --simulate --capture --interface wlan0   --duration 3600 --interval 10 --post-process --accept
```

## User data

Local input remains under `myinfo/`:

```text
myinfo/exclusions.txt
myinfo/oui.txt
```

`exclusions.txt` is used to remove known MAC addresses from filtered outputs.

`oui.txt` is used to add manufacturer information to enriched outputs.

## Safety boundary

Attack-related actions are retained only for owned or explicitly authorized lab environments.

## Documentation set

This package contains:

```text
wifi_air_suite.sh
README.md
INSTALL.md
CHANGELOG.md
WHY.md
SPECIFICATIONS.md
SPECIFICATIONS_FR.md
SPECIFICATIONS_GLOBAL.md
SPECIFICATIONS_GLOBAL_FR.md
```
