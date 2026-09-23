# wifi_air_suite - Product Guide

Version: **v3.0.0**  
Author: **Bruno DELNOZ / @NoXoZ.be**  
Release date: **September 23, 2026**  
Status: **Major Release / Linux-Kali**  
Repository: `github.com/bdelnoz/wifi_air_suite`

`wifi_air_suite` is a unified Wi-Fi capture, inspection, post-processing and authorized-lab toolkit for Linux/Kali. The v3.0.0 release is a clean major baseline built from the validated v2.1.4 implementation. It preserves the established operational behavior while bringing the script, examples, specifications, installation notes, rationale and product documentation onto one release baseline.

> Active wireless actions are intended only for networks and devices you own or are explicitly authorized to test.

## Contents

1. Overview
2. Installation and package layout
3. Execution model and safety gates
4. Capture fundamentals
5. Targeted BSSID capture with `--channel`
6. Interval capture and long-running workflows
7. Post-processing and generated artifacts
8. Exclusions and OUI manufacturer enrichment
9. Logging modes and `--nolog`
10. Inspection and explicit cracking workflows
11. Authorized-lab actions
12. Runtime layout and storage management
13. Complete option reference
14. Worked examples
15. Troubleshooting
16. Frequently asked questions
17. Version history and release summary

## 1. Overview

### 1.1 What v3.0.0 is

v3.0.0 is the major-release baseline of the current `wifi_air_suite` CLI. The major version does not hide a behavior rewrite: it promotes the validated v2.1.4 implementation into a fully consolidated release with current documentation and a complete Product Guide.

### 1.2 Core principles

- Capture stays capture-only: `--capture` runs `airodump-ng` and never implicitly starts cracking or active actions.
- Real operational work requires the explicit `--exec` gate.
- `--simulate` provides a non-operational dry run.
- Exactly one action is selected per invocation.
- Long captures can be sliced with `--interval`.
- Persistent terminal logs can be disabled with `--nolog` while CAP/CSV and post-processing outputs remain available.
- Manufacturer data can be refreshed with `--update-oui`.
- A known BSSID can be pinned to a known channel with `--channel N`.

### 1.3 Main use cases

| Use case | Relevant features |
|---|---|
| General RF inventory | `--capture`, multi-channel hopping |
| Focused AP observation | `--bssid`, optional `--channel` |
| Long investigation | `--interval`, `--post-process`, `--nolog` |
| Manufacturer attribution | `--update-oui`, enriched CSV |
| Noise reduction | `myinfo/exclusions.txt` |
| Capture inspection | `--check` |
| Explicit wordlist test | `--crack`, `--wordlist`, `--bssid` |
| Authorized lab validation | `--attack-hosts`, `--attack-preauth`, `--test-injection` |

## 2. Installation and package layout

### 2.1 Files in the complete package

```text
wifi_air_suite.sh
set_unset_to_monitor.sh
README.md
INSTALL.md
SPECIFICATIONS.md
EXAMPLES.md
WHY.md
CHANGELOG.md
PRODUCT_GUIDE.md
wifi_air_suite_v3.0.0_Product_Guide.pdf
.gitignore
myinfo/
  exclusions.txt
  exclusions_enrichi.txt
  exclusions_oui_resolved.txt
```

`myinfo/oui.txt` is intentionally not shipped as a placeholder. Populate it from the maintained IEEE source with `./wifi_air_suite.sh --update-oui`.

### 2.2 Permissions and first checks

```bash
chmod +x wifi_air_suite.sh set_unset_to_monitor.sh
./wifi_air_suite.sh --version
./wifi_air_suite.sh --prerequis
./wifi_air_suite.sh --init
./wifi_air_suite.sh --update-oui
./wifi_air_suite.sh --doctor
```

### 2.3 Expected platform

The suite targets Linux/Kali and expects the Aircrack-ng ecosystem plus standard networking and GNU utilities. The script can install its supported package set through `--install`.

## 3. Execution model and safety gates

### 3.1 Real execution

```bash
./wifi_air_suite.sh --exec --capture [options]
```

Operational actions require `--exec`.

### 3.2 Simulation

```bash
./wifi_air_suite.sh --simulate --capture [options]
```

Simulation resolves and prints the requested configuration without performing privileged/system/network changes.

### 3.3 One action per invocation

The parser rejects conflicting actions. `--capture`, `--check`, `--crack`, `--attack-hosts`, `--attack-preauth` and `--test-injection` remain explicit and separate.

## 4. Capture fundamentals

### 4.1 Five-minute capture

```bash
./wifi_air_suite.sh --exec --capture \
  --interface wlan0 \
  --duration 300
```

### 4.2 Infinite capture

```bash
./wifi_air_suite.sh --exec --capture \
  --interface wlan0 \
  --infinite
```

### 4.3 Default multi-channel behavior

Without `--channel`, the capture engine uses this established channel set:

```text
1,2,3,4,5,6,7,8,9,10,11,12,13,14,
36,40,44,48,52,56,60,64,
100,104,108,112,116,120,124,128,132,136,140,144,
149,153,157,161,165
```

The command also enables manufacturer display, ACK display, beacons, uptime, WPS information, CSV/PCAP output and periodic write updates.

## 5. Targeted BSSID capture with `--channel`

### 5.1 Why it exists

When both the BSSID and its RF channel are already known, hopping through unrelated channels wastes dwell time. v3.0.0 therefore includes the targeted-channel option introduced in the validated v2.1.4 baseline.

### 5.2 Exact example

```bash
./wifi_air_suite.sh --exec --capture \
  --interface wlan0 \
  --bssid C6:4F:D5:24:D3:1E \
  --channel 4 \
  --duration 300 \
  --post-process \
  --nolog
```

With `--channel 4`, `airodump-ng` is given only channel 4. Without `--channel`, the normal multi-channel list is preserved.

### 5.3 Validation rules

`--channel`:

- is valid only with `--capture`;
- requires `--bssid MAC`;
- accepts only channels already supported by the capture engine;
- does not change the behavior of unrelated actions.

## 6. Interval capture and long-running workflows

`--interval N` is in minutes; `--duration` remains in seconds.

### 6.1 One hour in 10-minute slices

```bash
./wifi_air_suite.sh --exec --capture \
  --interface wlan0 \
  --duration 3600 \
  --interval 10 \
  --post-process \
  --nolog
```

This produces six independent slices. Every slice receives a new collision-safe prefix and normal `-01.cap` / `-01.csv` files.

### 6.2 Infinite sliced capture

```bash
./wifi_air_suite.sh --exec --capture \
  --interface wlan0 \
  --infinite \
  --interval 10 \
  --post-process \
  --accept \
  --nolog
```

Monitor mode is entered once and retained between slices. Stop with Ctrl+C or with `--stop` from another terminal when the runtime PID is registered.

## 7. Post-processing and generated artifacts

With `--post-process`, each completed slice can generate:

```text
.results/csv/        copied raw CSV
.results/filtered/   filtered CSV + filtered Markdown
.results/enriched/   manufacturer-enriched CSV
.results/generated/  generated/copy artifacts
```

### 7.1 Filtered Markdown

The Markdown is generated from the already filtered CSV, so the CSV and Markdown represent the same filtered data set. Access points and stations are rendered as separate Markdown tables.

### 7.2 Open automatically in Kate

```bash
./wifi_air_suite.sh --exec --capture \
  --interface wlan0 \
  --duration 300 \
  --post-process \
  --open-kate
```

`--open-kate` requires `--post-process` and launches Kate asynchronously.

## 8. Exclusions and OUI manufacturer enrichment

### 8.1 Exclusions

The default exclusion source is:

```text
myinfo/exclusions.txt
```

MAC addresses from this file are removed from filtered/post-processed results. Raw RF capture remains untouched.

The complete package also carries the human-readable companion files:

```text
myinfo/exclusions_enrichi.txt
myinfo/exclusions_oui_resolved.txt
```

### 8.2 Override exclusions

```bash
./wifi_air_suite.sh --exec --capture \
  --interface wlan0 \
  --duration 300 \
  --post-process \
  --exclusions-file /path/to/custom_exclusions.txt
```

### 8.3 Update OUI manufacturer data

```bash
./wifi_air_suite.sh --update-oui
```

The updater downloads the IEEE Registration Authority MA-L/OUI listing, normalizes it to the format used by the suite, validates that at least 10,000 entries were recognized, backs up the previous local file and installs the new database only after validation succeeds.

Simulation:

```bash
./wifi_air_suite.sh --simulate --update-oui
```

## 9. Logging modes and `--nolog`

### 9.1 Default logging

Normal operation can create a global log and an airodump terminal log under `.results/logs/`. Live non-spinner capture uses a PTY so the full airodump display remains visible while being recorded.

### 9.2 No persistent logs

```bash
./wifi_air_suite.sh --exec --capture \
  --interface wlan0 \
  --duration 3600 \
  --post-process \
  --nolog
```

`--nolog` / `--no-log` disables persistent `.log` files for that invocation. It does **not** disable CAP, CSV, filtered CSV, filtered Markdown, enriched CSV or generated outputs.

## 10. Inspection and explicit cracking workflows

### 10.1 Check a capture

```bash
./wifi_air_suite.sh --exec --check --offset 1
```

Or target one capture and BSSID:

```bash
./wifi_air_suite.sh --exec --check \
  --cap-file .results/cap/capture.cap \
  --bssid AA:BB:CC:DD:EE:FF
```

The check is bounded and non-interactive.

### 10.2 Explicit wordlist action

```bash
./wifi_air_suite.sh --exec --crack \
  --cap-file .results/cap/capture.cap \
  --bssid AA:BB:CC:DD:EE:FF \
  --wordlist /path/to/wordlist.txt
```

`--crack` requires both a BSSID and a wordlist and is never started implicitly by capture.

## 11. Authorized-lab actions

The suite keeps active wireless operations behind explicit actions. They are intended for owned/authorized lab environments.

### 11.1 Deauthentication from selected CSV pairs

```bash
./wifi_air_suite.sh --simulate --attack-hosts \
  --interface wlan1 \
  --csv-file .results/cap/lab-01.csv \
  --bssid AA:BB:CC:DD:EE:FF \
  --station 11:22:33:44:55:66
```

Use simulation to verify selection before any authorized real execution.

### 11.2 Fake authentication and injection test

The distinct actions are:

```text
--attack-preauth
--test-injection
```

They never run as side effects of `--capture`.

## 12. Runtime layout and storage management

Default runtime root:

```text
.results/
  cap/
  csv/
  filtered/
  enriched/
  generated/
  logs/
  tmp/
  archive/
```

### 12.1 Custom result disk

```bash
./wifi_air_suite.sh --exec --capture \
  --interface wlan0 \
  --infinite --interval 10 --post-process --nolog \
  --dest-dir /mnt/data3_81g/wifi_results
```

### 12.2 Maintenance

```bash
./wifi_air_suite.sh --list-captures
./wifi_air_suite.sh --list-csv
./wifi_air_suite.sh --clean-tmp
./wifi_air_suite.sh --purge
./wifi_air_suite.sh --stop
```

`--purge` manages runtime artifacts only; `myinfo/` and source/documentation files are preserved.

## 13. Complete option reference

| Option | Purpose |
|---|---|
| `--help`, `-h` | Complete help |
| `--version` | Current version |
| `--changelog`, `-ch` | Internal changelog |
| `--exec`, `-exe` | Real operational gate |
| `--simulate`, `-s`, `--dry-run` | Non-operational simulation |
| `--prerequis`, `-pr` | Prerequisite check |
| `--install`, `-i` | Install supported packages |
| `--doctor` | Diagnostics |
| `--init` | Initialize layout |
| `--show-paths` | Show resolved paths |
| `--print-config` | Show resolved configuration |
| `--update-oui` | Refresh manufacturer database |
| `--capture` | Capture-only action |
| `--check` | Bounded inspection |
| `--crack` | Explicit wordlist test |
| `--attack-hosts` | Authorized/lab deauth action |
| `--attack-preauth` | Authorized/lab fakeauth action |
| `--test-injection` | Authorized/lab injection test |
| `--interface IFACE` | Wi-Fi interface |
| `-d`, `--duration SECONDS` | Finite capture duration |
| `--infinite` | Unlimited capture |
| `--interval MINUTES` | Independent capture slices |
| `-b`, `--bssid MAC` | BSSID selection/filter |
| `--channel N` | Single channel for targeted BSSID capture |
| `--station MAC` | Station/client selection |
| `--post-process` | Generate analytical outputs |
| `--no-post-process` | Disable post-processing |
| `--open-kate` | Open filtered Markdown |
| `--accept` | Compatibility acceptance mode |
| `--archive-old` | Archive older runtime outputs |
| `--spinner` | Lightweight timed-capture display |
| `--no-spinner` | Full live display |
| `--nolog`, `--no-log` | Disable persistent logs |
| `-o`, `--offset N` | Select Nth newest file |
| `--all` | Select all CSV files where supported |
| `--cap-file FILE` | Explicit capture file |
| `--csv-file FILE` | Explicit CSV file |
| `-X`, `--exclusions-file FILE` | Override exclusions |
| `-w`, `--wordlist FILE` | Wordlist for explicit crack |
| `--deauth-count N` | Authorized deauth frame count |
| `--dest_dir`, `--dest-dir DIR` | Override runtime root |
| `--stop`, `-st` | Stop registered invocation |
| `--clean-tmp` | Clean temporary runtime files |
| `--purge`, `-pu`, `--clean-runtime` | Purge managed runtime files |

## 14. Worked examples

### A. Fast five-minute inventory

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 300 --post-process --nolog
```

### B. Focused five-minute BSSID/channel capture

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --bssid C6:4F:D5:24:D3:1E --channel 4 \
  --duration 300 --post-process --nolog
```

### C. One-hour sliced investigation

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 \
  --post-process --accept --nolog
```

### D. Infinite overnight workflow

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 15 \
  --post-process --accept --nolog
```

### E. Refresh OUI before analysis

```bash
./wifi_air_suite.sh --update-oui
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 600 --post-process --nolog
```

## 15. Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| Interface not found | Wrong interface name or monitor transition issue | `./wifi_air_suite.sh --doctor`; inspect `iw dev` |
| `--channel` rejected | Missing BSSID, wrong action or unsupported channel | Use with `--capture --bssid`; verify supported list |
| No filtered Markdown | `--post-process` not enabled | Add `--post-process` |
| Kate does not open | Kate missing or `--open-kate` used without post-process | Install Kate; use both options |
| Manufacturer is `Unknown` | OUI file missing/stale | Run `--update-oui` |
| Logs consume too much space | Persistent PTY logging enabled | Add `--nolog` for future captures |
| No CAP selected by check | Runtime root/offset mismatch | Use `--list-captures`, `--cap-file`, or correct `--dest-dir` |
| Sudo prompt/action fails | No usable controlling terminal or ticket | Run from a normal terminal; use `--doctor` |
| Post-process output still contains known MAC | Exclusion file incomplete or wrong override | Inspect `myinfo/exclusions.txt` and `-X` path |

## 16. Frequently asked questions

### Does `--channel` replace `--bssid`?

No. It complements it. The current contract intentionally requires `--bssid` whenever `--channel` is supplied.

### What happens if I omit `--channel`?

Nothing changes: the established multi-channel list is used.

### Does `--nolog` mean no results?

No. It disables persistent `.log` files only. CAP/CSV and analytical post-processing artifacts remain available.

### Does capture automatically crack?

No. Capture, check and crack are separate actions.

### Does `--post-process` change raw capture data?

No. Filtering and enrichment operate on copied/derived CSV artifacts. Raw CAP/CSV capture remains available.

### Why is `oui.txt` not shipped in the release package?

To avoid replacing a user's maintained local database with a stale or placeholder file. Use `--update-oui` to create/update the local database from the IEEE source.

### Where are all command examples?

`EXAMPLES.md` is the exhaustive command catalog and should be treated as the detailed CLI cookbook.

## 17. Version history and release summary

| Version | Summary |
|---|---|
| v3.0.0 | Major consolidated baseline; complete documentation/Product Guide; preserves validated v2.1.4 behavior |
| v2.1.4 | Added targeted BSSID `--channel N` capture |
| v2.1.3 | Added validated `--update-oui` workflow |
| v2.1.2 | Added `--nolog` / `--no-log` |
| v2.1.1 | Monitor helper resolved beside main script |
| v2.1.0 | Filtered Markdown and optional Kate opening |
| v2.0.0 | Interval capture and per-slice post-processing |

### v3.0.0 release checklist

- Main script reports `v3.0.0`.
- Bash syntax validates successfully.
- `--channel` parser/validation/build path is present.
- Existing multi-channel behavior remains the default.
- README, INSTALL, SPECIFICATIONS, EXAMPLES, WHY and CHANGELOG identify v3.0.0 as the current release.
- Product Guide is included in Markdown and PDF form.
- The three validated exclusion files are included unchanged from the supplied v2.1.4 package baseline.
- No checksum file is included.
- No placeholder `oui.txt` is included.

For exact CLI edge cases and the largest command catalog, see `EXAMPLES.md`. For design contracts, see `SPECIFICATIONS.md`. For installation, see `INSTALL.md`. For release history, see `CHANGELOG.md`.
