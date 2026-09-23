# wifi_air_suite — EXAMPLES

Version: **v3.0.0**  
Main command: `./wifi_air_suite.sh`

This file is the exhaustive practical command catalog for the current CLI. It covers every action and every parsed option, common combinations, expected behavior, output locations, aliases, simulation modes and common invalid combinations.

> Active wireless actions (`--attack-hosts`, `--attack-preauth`, `--test-injection`) are intended only for networks/devices you own or are explicitly authorized to test.

---

## 1. Basic syntax and execution model

The script has three broad categories:

1. **Operational actions** — real execution requires `--exec`.
2. **Simulation** — `--simulate` / `-s` shows what an operational action would do without changing the network/system.
3. **Information / maintenance actions** — can run directly without `--exec`, including `--update-oui`.

General operational form:

```bash
./wifi_air_suite.sh --exec --<action> [options]
```

Simulation form:

```bash
./wifi_air_suite.sh --simulate --<action> [options]
```

Only one business/control action is accepted per invocation.

### Show the complete built-in help

```bash
./wifi_air_suite.sh --help
```

Short form:

```bash
./wifi_air_suite.sh -h
```

### Show the version

```bash
./wifi_air_suite.sh --version
```

Expected for this package:

```text
v3.0.0
```

### Show the internal changelog

```bash
./wifi_air_suite.sh --changelog
```

Alias:

```bash
./wifi_air_suite.sh -ch
```

---

## 2. Prerequisites and installation

### Check all supported prerequisites

```bash
./wifi_air_suite.sh --prerequis
```

Short alias:

```bash
./wifi_air_suite.sh -pr
```

Compatibility aliases:

```bash
./wifi_air_suite.sh --prereq
./wifi_air_suite.sh --prereqs
./wifi_air_suite.sh --prerequisite
./wifi_air_suite.sh --prerequisites
./wifi_air_suite.sh --check-prereq
./wifi_air_suite.sh --check-prereqs
```

The check reports tools such as Aircrack-ng, `iw`, `iwconfig`, NetworkManager utilities, GNU tools, `script`, `timeout` and `curl`.

### Install the supported package set with APT

```bash
./wifi_air_suite.sh --install
```

Short alias:

```bash
./wifi_air_suite.sh -i
```

The current supported set includes Aircrack-ng, util-linux, `iw`, wireless-tools, NetworkManager, standard GNU tools and `curl`.

### Simulate package installation

```bash
./wifi_air_suite.sh --simulate --install
```

This prints the APT command without running it.

---

## 3. Initialize and inspect the project/runtime layout

### Initialize expected directories and local files

```bash
./wifi_air_suite.sh --init
```

Creates/ensures the `myinfo/` and `.results/` layout.

### Show all resolved paths

```bash
./wifi_air_suite.sh --show-paths
```

This includes the project root, monitor helper, exclusions file, OUI file, OUI backup, OUI source URL, runtime directories and PID file.

### Print the complete resolved configuration

```bash
./wifi_air_suite.sh --print-config
```

Useful before a real operation to confirm interface, duration, interval, post-processing, logging mode, file selectors and OUI paths.

### Run the diagnostic view

```bash
./wifi_air_suite.sh --doctor
```

`--doctor` prints paths, prerequisite status, detected Wi-Fi interfaces and the current runtime inventory.

---

## 4. Update the OUI/manufacturer database

### Normal update from IEEE

```bash
./wifi_air_suite.sh --update-oui
```

What it does:

1. downloads the IEEE Registration Authority MA-L/OUI public text listing;
2. stores the temporary download under `.results/tmp/`;
3. extracts valid IEEE `(hex)` OUI rows;
4. converts them to `AA:BB:CC<TAB>Manufacturer Name`;
5. requires at least 10,000 valid entries;
6. saves the existing `myinfo/oui.txt` as `myinfo/oui.txt.bak`;
7. installs the validated database as `myinfo/oui.txt`.

Default source:

```text
https://standards-oui.ieee.org/oui/oui.txt
```

No `--exec` is required because this is a local maintenance action.

### Simulate the OUI update

```bash
./wifi_air_suite.sh --simulate --update-oui
```

This prints the source, destination, backup path and validation requirement without downloading or replacing anything.

### Override the OUI source for a mirror or local test

```bash
WIFI_AIR_SUITE_OUI_URL="https://example.invalid/oui.txt" \
  ./wifi_air_suite.sh --update-oui
```

Local test source with curl-compatible `file://` URI:

```bash
WIFI_AIR_SUITE_OUI_URL="file:///tmp/oui-test.txt" \
  ./wifi_air_suite.sh --update-oui
```

The replacement is refused if the source is empty, cannot be downloaded or produces fewer than 10,000 recognized OUI rows.

### Inspect the updated database

```bash
head -n 20 myinfo/oui.txt
wc -l myinfo/oui.txt
ls -lh myinfo/oui.txt myinfo/oui.txt.bak
```

---

## 5. Capture — shortest forms

### 20-second capture

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 --duration 20
```

Equivalent short duration option:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 -d 20
```

This runs only `airodump-ng`; it does not automatically run check, crack or an active action.

### Infinite capture until Ctrl+C

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 --infinite
```

A capture without `--duration` also behaves as an unbounded capture unless another timing mode changes it:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0
```

### Simulate a capture

```bash
./wifi_air_suite.sh --simulate --capture --interface wlan0 --duration 20
```

Compatibility alias:

```bash
./wifi_air_suite.sh --dry-run --capture --interface wlan0 --duration 20
```

---

## 6. Capture with interval slicing

`--interval N` is expressed in **minutes**. `--duration` remains expressed in **seconds**.

### One hour split into 10-minute captures

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10
```

Expected: six independent capture slices, each with a fresh prefix and normal `-01.cap` / `-01.csv` files.

### 65 minutes split into 10-minute slices

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3900 --interval 10
```

Expected: six 10-minute slices plus one final 5-minute remainder slice.

### Infinite 10-minute slices

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 10
```

Stop with Ctrl+C or, from another terminal, use `--stop` if the runtime PID is registered.

### Infinite 1-minute slices

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 1
```

Useful for highly granular result files, but it produces many CAP/CSV files over time.

---

## 7. Post-processing

### Capture and post-process the result

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 300 --post-process
```

`--post-process` generates/copied artifacts in:

```text
.results/csv/
.results/filtered/
.results/enriched/
.results/generated/
```

### Interval capture with post-processing after every slice

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 --post-process
```

Each completed slice is post-processed before the next slice starts.

### Explicitly disable post-processing

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 300 --no-post-process
```

`--no-post-process` is useful when a generic wrapper adds `--post-process` and you want to override it later in the command line.

---

## 8. Open filtered Markdown automatically in Kate

### Post-process and open generated Markdown

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 300 --post-process --open-kate
```

`--open-kate` requires `--post-process`.

### Interval workflow with Kate

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 --post-process --open-kate
```

Every completed interval produces a filtered Markdown and opens it asynchronously in Kate.

Invalid example:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 300 --open-kate
```

This is rejected because `--open-kate` requires `--post-process`.

---

## 9. `--accept`

### Capture with compatibility acceptance mode

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 --post-process --accept
```

`--accept` represents non-interactive acceptance semantics for compatible/current/future gates. It does **not** bypass sudo authentication.

Typical infinite workflow:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 10 --post-process --accept
```

---

## 10. Disable persistent logs with `--nolog`

Aliases:

```text
--nolog
--no-log
```

### One-hour capture without persistent `.log` files

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --nolog
```

CAP/CSV outputs are still generated.

### Recommended long-running workflow

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 10 --post-process --accept --nolog
```

This preserves capture/post-processing data but prevents creation of the large terminal recordings such as `airodump-<prefix>.log`.

### Alias form

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 600 --no-log
```

### `--nolog` with Kate

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 10 --post-process --open-kate --nolog
```

### `--nolog` does not delete old logs

To inspect old logs:

```bash
ls -lh .results/logs/
```

To remove managed runtime artifacts, use `--purge` explicitly; `--nolog` itself only changes new logging for the current invocation.

---

## 11. Spinner versus live airodump display

### Default live display

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 --duration 120
```

Without `--spinner`, the normal airodump table is shown live.

### Timed capture with spinner

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 120 --spinner
```

The full-screen airodump UI is hidden and a lightweight spinner is shown.

### Explicitly disable spinner

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 120 --no-spinner
```

### Spinner plus no persistent logs

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 120 --spinner --nolog
```

The spinner remains visible while airodump terminal output is discarded instead of being saved to a log.

---

## 12. Archive older result files before a new capture

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 300 --archive-old
```

With intervals, archiving runs once before the first slice:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 --archive-old --post-process
```

Older managed result files are moved into `.results/archive/` with `.done` naming.

---

## 13. Restrict capture by BSSID

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 300 --bssid AA:BB:CC:DD:EE:FF
```

Short alias:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  -d 300 -b AA:BB:CC:DD:EE:FF
```

Combine with post-processing and no logs:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 1800 --interval 5 \
  --bssid AA:BB:CC:DD:EE:FF \
  --post-process --nolog
```

The MAC must use the six-octet colon-separated format.

### Target one BSSID on one known channel

```bash
./wifi_air_suite.sh --exec --capture \
  --interface wlan0 \
  --bssid C6:4F:D5:24:D3:1E \
  --channel 4 \
  --duration 300 \
  --post-process \
  --nolog
```

`--channel` prevents the normal channel-hopping list from being used. It is intentionally valid only for `--capture` and requires `--bssid`.

Simulation:

```bash
./wifi_air_suite.sh --simulate --capture \
  --interface wlan0 \
  --bssid C6:4F:D5:24:D3:1E \
  --channel 4 \
  --duration 300 \
  --post-process \
  --nolog
```

Without `--channel`, the normal multi-channel list remains active.

---

## 14. Interface selection

### Use `wlan0`

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 --duration 60
```

### Use another adapter

```bash
./wifi_air_suite.sh --exec --capture --interface wlan2 --duration 60
```

### Request an existing monitor interface explicitly

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0mon --duration 60
```

There is deliberately **no `-i` short alias for interface**, because `-i` is reserved for `--install`.

---

## 15. Custom runtime root with `--dest_dir` / `--dest-dir`

### Relative destination

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 600 --dest-dir .results_test
```

Relative paths are resolved below the script directory.

### Absolute destination

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 600 \
  --dest-dir /mnt/data3_81g/wifi_capture_results
```

Underscore spelling is also accepted:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 600 --dest_dir /mnt/data3_81g/wifi_capture_results
```

### Long capture on another disk without logs

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 10 --post-process --nolog \
  --dest-dir /mnt/data3_81g/wifi_capture_results
```

---

## 16. Exclusion file selection

Default:

```text
myinfo/exclusions.txt
```

Override with:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 300 --post-process \
  --exclusions-file /path/to/custom_exclusions.txt
```

Short alias:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  -d 300 --post-process -X /path/to/custom_exclusions.txt
```

The exclusions affect filtered/post-processed data, not the raw radio capture itself.

---

## 17. List available capture and CSV files

### List CAP files

```bash
./wifi_air_suite.sh --list-captures
```

### List CSV files

```bash
./wifi_air_suite.sh --list-csv
```

These use the active runtime root; combine the runtime-root option when needed:

```bash
./wifi_air_suite.sh --dest-dir /mnt/data3_81g/wifi_capture_results --list-captures
```

```bash
./wifi_air_suite.sh --dest-dir /mnt/data3_81g/wifi_capture_results --list-csv
```

---

## 18. Check/inspect a capture

### Check the newest capture

```bash
./wifi_air_suite.sh --exec --check --offset 1
```

Short offset alias:

```bash
./wifi_air_suite.sh --exec --check -o 1
```

### Check the second-newest capture

```bash
./wifi_air_suite.sh --exec --check --offset 2
```

### Check a specific CAP file

```bash
./wifi_air_suite.sh --exec --check \
  --cap-file .results/cap/20260923_080000_1-01.cap
```

### Check a specific BSSID in a specific CAP file

```bash
./wifi_air_suite.sh --exec --check \
  --cap-file .results/cap/20260923_080000_1-01.cap \
  --bssid AA:BB:CC:DD:EE:FF
```

### Simulate check selection

```bash
./wifi_air_suite.sh --simulate --check --offset 1
```

The check action is bounded and non-interactive; it does not start cracking automatically.

---

## 19. Explicit crack action

`--crack` requires both a BSSID and a wordlist.

### Crack newest selected CAP

```bash
./wifi_air_suite.sh --exec --crack \
  --offset 1 \
  --bssid AA:BB:CC:DD:EE:FF \
  --wordlist /path/to/wordlist.txt
```

Short aliases:

```bash
./wifi_air_suite.sh --exec --crack \
  -o 1 \
  -b AA:BB:CC:DD:EE:FF \
  -w /path/to/wordlist.txt
```

### Crack an explicit capture

```bash
./wifi_air_suite.sh --exec --crack \
  --cap-file .results/cap/20260923_080000_1-01.cap \
  --bssid AA:BB:CC:DD:EE:FF \
  --wordlist /path/to/wordlist.txt
```

### Simulate crack configuration

```bash
./wifi_air_suite.sh --simulate --crack \
  --cap-file .results/cap/20260923_080000_1-01.cap \
  --bssid AA:BB:CC:DD:EE:FF \
  --wordlist /path/to/wordlist.txt
```

The simulation does not execute `aircrack-ng` cracking.

---

## 20. Select CSV input

For actions that consume CSV data, selection can use an explicit file, an offset, or `--all` where supported.

### Explicit CSV

```bash
./wifi_air_suite.sh --simulate --attack-hosts \
  --interface wlan1 \
  --csv-file .results/cap/20260923_080000_1-01.csv
```

### Newest CSV by offset

```bash
./wifi_air_suite.sh --simulate --attack-hosts \
  --interface wlan1 --offset 1
```

### Second-newest CSV

```bash
./wifi_air_suite.sh --simulate --attack-hosts \
  --interface wlan1 --offset 2
```

### All supported CSV files

```bash
./wifi_air_suite.sh --simulate --attack-hosts \
  --interface wlan1 --all
```

---

## 21. Station/BSSID selection for authorized lab actions

### Filter by one BSSID

```bash
./wifi_air_suite.sh --simulate --attack-hosts \
  --interface wlan1 \
  --offset 1 \
  --bssid AA:BB:CC:DD:EE:FF
```

### Filter by one station

```bash
./wifi_air_suite.sh --simulate --attack-hosts \
  --interface wlan1 \
  --offset 1 \
  --station 11:22:33:44:55:66
```

### Filter by both AP and station

```bash
./wifi_air_suite.sh --simulate --attack-hosts \
  --interface wlan1 \
  --offset 1 \
  --bssid AA:BB:CC:DD:EE:FF \
  --station 11:22:33:44:55:66
```

There is deliberately **no `-s` short alias for station**, because `-s` means `--simulate`.

---

## 22. Authorized/lab deauthentication action

Always test selection first with simulation:

```bash
./wifi_air_suite.sh --simulate --attack-hosts \
  --interface wlan1 \
  --csv-file .results/cap/lab-01.csv \
  --bssid AA:BB:CC:DD:EE:FF \
  --station 11:22:33:44:55:66
```

Real authorized/lab execution:

```bash
./wifi_air_suite.sh --exec --attack-hosts \
  --interface wlan1 \
  --csv-file .results/cap/lab-01.csv \
  --bssid AA:BB:CC:DD:EE:FF \
  --station 11:22:33:44:55:66
```

### Change the deauthentication frame count

Default count is `10`.

```bash
./wifi_air_suite.sh --exec --attack-hosts \
  --interface wlan1 \
  --csv-file .results/cap/lab-01.csv \
  --bssid AA:BB:CC:DD:EE:FF \
  --station 11:22:33:44:55:66 \
  --deauth-count 3
```

### Authorized/lab action without persistent logs

```bash
./wifi_air_suite.sh --exec --attack-hosts \
  --interface wlan1 \
  --csv-file .results/cap/lab-01.csv \
  --bssid AA:BB:CC:DD:EE:FF \
  --station 11:22:33:44:55:66 \
  --nolog
```

---

## 23. Authorized/lab pre-auth/fake-auth action

Simulation:

```bash
./wifi_air_suite.sh --simulate --attack-preauth \
  --interface wlan1 \
  --csv-file .results/cap/lab-01.csv \
  --bssid AA:BB:CC:DD:EE:FF \
  --station 11:22:33:44:55:66
```

Real authorized/lab execution:

```bash
./wifi_air_suite.sh --exec --attack-preauth \
  --interface wlan1 \
  --csv-file .results/cap/lab-01.csv \
  --bssid AA:BB:CC:DD:EE:FF \
  --station 11:22:33:44:55:66
```

Compatibility spelling:

```bash
./wifi_air_suite.sh --exec --attack-pre-auth \
  --interface wlan1 --offset 1
```

No-log variant:

```bash
./wifi_air_suite.sh --exec --attack-preauth \
  --interface wlan1 --offset 1 --nolog
```

---

## 24. Authorized/lab injection test

Simulation:

```bash
./wifi_air_suite.sh --simulate --test-injection --interface wlan1
```

Real authorized/lab test:

```bash
./wifi_air_suite.sh --exec --test-injection --interface wlan1
```

No persistent action log:

```bash
./wifi_air_suite.sh --exec --test-injection --interface wlan1 --nolog
```

---

## 25. Stop an active registered invocation

```bash
./wifi_air_suite.sh --stop
```

Alias:

```bash
./wifi_air_suite.sh -st
```

The command reads the runtime PID file and sends `TERM` to the invocation registered by this script.

Simulation:

```bash
./wifi_air_suite.sh --simulate --stop
```

---

## 26. Clean temporary runtime files

```bash
./wifi_air_suite.sh --clean-tmp
```

Only `.results/tmp/` is cleaned.

With a custom runtime root:

```bash
./wifi_air_suite.sh --dest-dir /mnt/data3_81g/wifi_capture_results --clean-tmp
```

---

## 27. Purge managed runtime artifacts

```bash
./wifi_air_suite.sh --purge
```

Short alias:

```bash
./wifi_air_suite.sh -pu
```

Compatibility alias:

```bash
./wifi_air_suite.sh --clean-runtime
```

Simulation:

```bash
./wifi_air_suite.sh --simulate --purge
```

`myinfo/` and source/documentation files are preserved.

---

## 28. Common complete workflows

### A. Fast 5-minute inventory with enrichment

```bash
./wifi_air_suite.sh --update-oui
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 300 --post-process --nolog
```

### B. One-hour investigation, 10-minute slices, no bulky logs

```bash
./wifi_air_suite.sh --update-oui
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 \
  --post-process --accept --nolog
```

### C. Infinite overnight scan, 15-minute slices

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 15 \
  --post-process --accept --nolog
```

### D. Infinite scan with every filtered Markdown opened in Kate

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 10 \
  --post-process --open-kate --accept --nolog
```

### E. Capture only one BSSID for 30 minutes

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 1800 \
  --bssid AA:BB:CC:DD:EE:FF \
  --post-process --nolog
```

### F. Put a long-running session on another disk

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 10 \
  --post-process --nolog \
  --dest-dir /mnt/data3_81g/wifi_results
```

### G. Inspect the newest result after capture

```bash
./wifi_air_suite.sh --exec --check --offset 1
```

### H. Refresh OUI, capture, then inspect generated enriched data

```bash
./wifi_air_suite.sh --update-oui
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 600 --post-process --nolog
ls -lh .results/enriched/
```

---

## 29. Useful result inspection commands outside the script

These are ordinary shell commands, not `wifi_air_suite` options.

### Show disk usage by runtime directory

```bash
du -sh .results/*
```

### Find the largest files

```bash
find .results -type f -printf '%s %p\n' | sort -nr | head -n 30
```

### Inspect only generated Markdown files

```bash
ls -1t .results/filtered/*.filtered.md 2>/dev/null
```

### Open the newest filtered Markdown in Kate manually

```bash
kate "$(ls -1t .results/filtered/*.filtered.md | head -n 1)" &
```

### Check how much space logs consume

```bash
du -sh .results/logs/
```

---

## 30. Option reference — every current CLI option

| Option | Meaning | Typical scope |
|---|---|---|
| `--help`, `-h` | Complete built-in help | informational |
| `--exec`, `-exe` | Authorize real operational execution | operational actions |
| `--simulate`, `-s` | Dry-run/simulation | actions |
| `--dry-run` | Compatibility alias for `--simulate` | actions |
| `--prerequis`, `-pr` | Prerequisite check | maintenance |
| `--prereq`, `--prereqs`, `--prerequisite`, `--prerequisites`, `--check-prereq`, `--check-prereqs` | Compatibility aliases for prerequisite check | maintenance |
| `--install`, `-i` | Install supported APT packages | maintenance |
| `--stop`, `-st` | Stop registered active invocation | control |
| `--purge`, `-pu` | Purge managed runtime artifacts | maintenance |
| `--clean-runtime` | Compatibility alias for `--purge` | maintenance |
| `--doctor` | Full diagnostic view | informational |
| `--init` | Initialize layout | maintenance |
| `--show-paths` | Print resolved paths | informational |
| `--print-config` | Print resolved configuration | informational |
| `--list-captures` | List CAP files | informational |
| `--list-csv` | List CSV files | informational |
| `--clean-tmp` | Clean temp files | maintenance |
| `--update-oui` | Refresh IEEE MA-L/OUI database | maintenance |
| `--version` | Print version | informational |
| `--changelog`, `-ch` | Print internal changelog | informational |
| `--capture` | Capture with airodump-ng only | business action |
| `--check` | Inspect capture | business action |
| `--crack` | Explicit wordlist cracking | business action |
| `--attack-hosts` | Authorized/lab deauthentication from CSV pairs | business action |
| `--attack-preauth`, `--attack-pre-auth` | Authorized/lab fake authentication from CSV pairs | business action |
| `--test-injection` | Authorized/lab injection test | business action |
| `--interface IFACE` | Select Wi-Fi interface | operational |
| `-d`, `--duration SECONDS` | Finite capture duration | capture |
| `--infinite` | Force infinite capture | capture |
| `--interval MINUTES` | Split capture into slices | capture |
| `--post-process` | Enable post-processing | capture |
| `--no-post-process` | Disable post-processing | capture |
| `--open-kate` | Open generated filtered Markdown | capture + post-process |
| `--accept` | Compatibility acceptance mode | capture |
| `--archive-old` | Archive old managed result files before capture | capture |
| `--spinner` | Hide full airodump UI and show spinner | timed capture |
| `--no-spinner` | Explicitly disable spinner | capture |
| `--nolog`, `--no-log` | Disable persistent `.log` files | capture/actions |
| `-o`, `--offset N` | Select Nth newest file | check/crack/CSV actions |
| `--all` | Process all CSV files where supported | CSV actions |
| `--cap-file FILE` | Explicit CAP selection | check/crack |
| `--csv-file FILE` | Explicit CSV selection | CSV actions |
| `-b`, `--bssid MAC` | BSSID filter | capture/check/crack/actions |
| `--channel N` | Restrict targeted BSSID capture to one supported channel; requires `--capture --bssid` | capture |
| `--station MAC` | Station/client filter | CSV actions |
| `-X`, `--exclusions-file FILE` | Override exclusions file | filtering/actions |
| `-w`, `--wordlist FILE` | Wordlist file | crack |
| `--deauth-count N` | Frame count per selected pair | attack-hosts |
| `--dest_dir DIR`, `--dest-dir DIR` | Override runtime root | runtime-aware actions |

---

## 31. Important validation rules and invalid combinations

### `--exec` and `--simulate` together

Invalid:

```bash
./wifi_air_suite.sh --exec --simulate --capture --interface wlan0 --duration 20
```

They are mutually exclusive.

### Operational action without either gate

Invalid:

```bash
./wifi_air_suite.sh --capture --interface wlan0 --duration 20
```

Use either:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 --duration 20
```

or:

```bash
./wifi_air_suite.sh --simulate --capture --interface wlan0 --duration 20
```

### More than one action

Invalid:

```bash
./wifi_air_suite.sh --exec --capture --check --interface wlan0
```

One explicit action per invocation.

### `--interval` outside capture

Invalid:

```bash
./wifi_air_suite.sh --exec --check --interval 10
```

`--interval` is capture-only.

### `--open-kate` without post-process

Invalid:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 --duration 60 --open-kate
```

Required:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 60 --post-process --open-kate
```

### Crack without wordlist

Invalid:

```bash
./wifi_air_suite.sh --exec --crack --bssid AA:BB:CC:DD:EE:FF
```

### Crack without BSSID

Invalid:

```bash
./wifi_air_suite.sh --exec --crack --wordlist /path/to/wordlist.txt
```

Both are intentionally required.

### `--channel` without `--bssid`

Invalid:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 --channel 4 --duration 60
```

Required form:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --bssid AA:BB:CC:DD:EE:FF --channel 4 --duration 60
```

### `--channel` outside capture

Invalid:

```bash
./wifi_air_suite.sh --exec --check --channel 4 --offset 1
```

### Invalid MAC syntax

Invalid:

```bash
./wifi_air_suite.sh --exec --check --bssid AABBCCDDEEFF
```

Expected syntax:

```text
AA:BB:CC:DD:EE:FF
```

### Invalid zero/negative duration, interval, offset or deauth count

Examples rejected by the parser:

```bash
./wifi_air_suite.sh --exec --capture --duration 0
./wifi_air_suite.sh --exec --capture --interval 0
./wifi_air_suite.sh --exec --check --offset 0
./wifi_air_suite.sh --exec --attack-hosts --deauth-count 0
```

These numeric options require positive integers.

---

## 32. What `--nolog` does and does not disable

With:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 600 --post-process --nolog
```

Still generated when applicable:

```text
CAP
raw CSV
copied CSV
filtered CSV
filtered Markdown
enriched CSV
generated copies
```

Not generated for that invocation:

```text
global .log
airodump terminal .log
action .log
```

Existing old `.log` files are not removed.

---

## 33. What `--update-oui` changes

Before update:

```text
myinfo/oui.txt
```

After successful update:

```text
myinfo/oui.txt       <- new validated database
myinfo/oui.txt.bak   <- previous database
```

Temporary download/normalization files are removed after success. A validation failure leaves the current `oui.txt` unchanged.

The current enrichment code resolves manufacturers using the first 24 bits of the MAC address, therefore the updater intentionally normalizes the IEEE **MA-L/OUI** listing used by that lookup model.

---

## 34. Recommended first commands after unpacking

```bash
chmod +x wifi_air_suite.sh set_unset_to_monitor.sh
./wifi_air_suite.sh --version
./wifi_air_suite.sh --prerequis
./wifi_air_suite.sh --init
./wifi_air_suite.sh --update-oui
./wifi_air_suite.sh --doctor
```

Then test your intended capture in simulation:

```bash
./wifi_air_suite.sh --simulate --capture --interface wlan0 \
  --duration 300 --post-process --nolog
```

Then run the same workflow for real:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 300 --post-process --nolog
```

---

## 35. Recommended high-volume command

For long investigation sessions where the airodump terminal logs are not useful and disk usage matters:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite \
  --interval 10 \
  --post-process \
  --accept \
  --nolog
```

This is the principal high-volume capture pattern for v3.0.0: independent 10-minute slices, per-slice processing, persistent analytical artifacts, no large terminal `.log` files.
