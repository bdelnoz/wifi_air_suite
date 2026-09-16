<!--
DOCUMENT INFORMATION
Document Name: INSTALL.md
Author: Bruno DELNOZ
Email: bruno.delnoz@protonmail.com
Version: v2.1.1
Date / Time: 2026-09-16 03:05
Project: Package scan WIFI / wifi_air_suite.sh
Short description: Installation, prerequisites, initialization and first-run guide.
-->
# INSTALL — wifi_air_suite.sh — v2.1.1

## 1. Target environment

The script is designed for Linux/Kali-style environments with Aircrack-ng tooling and a Wi-Fi interface usable in monitor mode.

## 2. Place the project files

Expected operational location:

```text
wifi_air_suite/
```

The main script and monitor helper must be in the same directory:

```text
wifi_air_suite.sh
set_unset_to_monitor.sh
```

Make both executable:

```bash
chmod +x wifi_air_suite.sh set_unset_to_monitor.sh
```

The main script resolves the helper as `$BASE_DIR/set_unset_to_monitor.sh`.

## 3. Check prerequisites

Run:

```bash
./wifi_air_suite.sh --prerequis
```

Main packages include:

```text
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
```

## 4. Automatic prerequisite installation

```bash
./wifi_air_suite.sh --install
```

The script handles sudo authentication internally. Starting the complete script with external `sudo` remains supported but is not required.

## 5. Initialize directories

```bash
./wifi_air_suite.sh --init
```

Expected runtime structure:

```text
.results/
├── cap/
├── csv/
├── filtered/
├── enriched/
├── generated/
├── logs/
├── tmp/
└── archive/
```

Expected local input directory:

```text
myinfo/
```

with:

```text
myinfo/exclusions.txt
myinfo/oui.txt
```

If `oui.txt` is created empty, replace it with the actual OUI database before expecting manufacturer enrichment.

## 6. Verify paths and state

```bash
./wifi_air_suite.sh --show-paths
./wifi_air_suite.sh --doctor
```

## 7. Safe simulation test

```bash
./wifi_air_suite.sh --simulate --capture --interface wlan0   --duration 3600   --interval 10   --post-process   --accept
```

Expected configuration includes:

```text
DURATION=3600
INTERVAL_MINUTES=10
POST_PROCESS=1
ACCEPT_MODE=1
```

## 8. Real capture examples

Single 20-second capture:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0   --duration 20 --post-process
```

One hour split into six ten-minute slices:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0   --duration 3600   --interval 10   --post-process   --accept
```

Infinite rolling ten-minute slices:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0   --infinite   --interval 10   --post-process   --accept
```

## 9. Important unit rule

```text
--duration = seconds
--interval = minutes
```


## Automatic filtered Markdown + Kate

`--post-process` now also creates `*.filtered.md` beside every `*.filtered.csv`.

To open each new Markdown result in Kate as soon as it is created:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 --post-process --open-kate --accept
```

When `--open-kate` is used, `kate` must be available in `PATH`. The editor is launched asynchronously and does not pause the interval loop. `--open-kate` requires `--post-process`.

## 10. Post-processing inputs

Filtering uses:

```text
myinfo/exclusions.txt
```

OUI enrichment uses:

```text
myinfo/oui.txt
```

Processed results are written under:

```text
.results/csv/
.results/filtered/
.results/enriched/
.results/generated/
```

## 11. Live display

The default capture path uses util-linux `script` to allocate a PTY and preserve the normal live `airodump-ng` table.

`--spinner` intentionally hides the full-screen airodump display.

## 12. Sudo behavior

Normal invocation:

```bash
./wifi_air_suite.sh --exec --capture ...
```

The script validates sudo on the controlling terminal and refreshes the valid ticket during long operations.

`--accept` never bypasses sudo authentication.

## 13. Stop an active invocation

```bash
./wifi_air_suite.sh --stop
```

## 14. Runtime cleanup

```bash
./wifi_air_suite.sh --clean-tmp
./wifi_air_suite.sh --purge
```

`myinfo/`, source and documentation are preserved by purge.

## 15. Installation acceptance criteria

Installation is ready when:

- `./wifi_air_suite.sh --version` prints `v2.1.1`;
- `./wifi_air_suite.sh --prerequis` reports required capture commands;
- interval simulation parses successfully;
- `.results/` can be initialized;
- `myinfo/exclusions.txt` exists;
- `myinfo/oui.txt` is present when manufacturer enrichment is required.
