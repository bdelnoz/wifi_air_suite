# wifi_air_suite

Version **v2.1.4** — Wi-Fi capture, inspection, post-processing and authorized lab actions for Linux/Kali.

The main entry point is `wifi_air_suite.sh`. Operational actions require the explicit `--exec` gate; `--simulate` provides a non-operational dry run. Capture is deliberately separated from check, crack and active lab actions.

## v2.1.4 highlight: targeted channel capture

`--channel N` restricts a targeted BSSID capture to one Wi-Fi channel. It is accepted only with `--capture` and requires `--bssid`. Without `--channel`, the existing multi-channel capture list is unchanged.

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --bssid C6:4F:D5:24:D3:1E --channel 4 \
  --duration 300 --post-process --nolog
```

## v2.1.3 highlight: `--update-oui`

`--update-oui` refreshes `myinfo/oui.txt` from the IEEE Registration Authority public MA-L/OUI listing. The download is staged in `.results/tmp/`, validated, normalized to the format used by `wifi_air_suite`, and only then installed.

```bash
./wifi_air_suite.sh --update-oui
```

The previous database is kept as `myinfo/oui.txt.bak`. A failed download or validation does **not** overwrite the current database. `curl` is preferred; `wget` is accepted as a fallback. The default source can be overridden for testing with `WIFI_AIR_SUITE_OUI_URL`.

Simulation without modifying the database:

```bash
./wifi_air_suite.sh --simulate --update-oui
```

See `EXAMPLES.md` for the exhaustive command catalog.

## v2.1.2 highlight: `--nolog`

`--nolog` (alias `--no-log`) disables persistent runtime `.log` files for the current invocation. It is intended for long or interval-based captures where terminal logs can consume a large amount of disk space.

With `--nolog`:

- no global `<prefix>.log` is created;
- no `airodump-<prefix>.log` is created;
- no persistent action log is created;
- `.cap`, `.csv`, filtered CSV, filtered Markdown, enriched CSV and generated outputs continue normally;
- live `airodump-ng` remains visible in the terminal when the spinner is disabled;
- existing log files are not deleted.

Without `--nolog`, the v2.1.1 logging behavior is preserved.

## Quick start

```bash
chmod +x wifi_air_suite.sh set_unset_to_monitor.sh
./wifi_air_suite.sh --prerequis
./wifi_air_suite.sh --doctor
```

Example long-running interval capture without persistent logs:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 10 --post-process --accept --nolog
```

Finite example:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 --post-process --nolog
```

## Main actions

- `--capture` — `airodump-ng` capture only.
- `--check` — bounded, non-interactive capture inspection with `aircrack-ng`.
- `--crack` — explicit `aircrack-ng` cracking action requiring `--wordlist` and `--bssid`.
- `--attack-hosts` — authorized/lab deauthentication using selected AP/station pairs from CSV.
- `--attack-preauth` — authorized/lab fake-authentication action.
- `--test-injection` — authorized/lab `aireplay-ng` injection test.

Capture never implicitly starts check, crack or attack actions.

## Runtime layout

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

The `logs/` directory still exists when `--nolog` is used, but the invocation does not create persistent `.log` files in it.

## Configuration files

```text
myinfo/exclusions.txt
myinfo/oui.txt
```

`exclusions.txt` contains MAC addresses to remove from filtered results. `oui.txt` is manufacturer/OUI data used by enrichment and can be refreshed with `./wifi_air_suite.sh --update-oui`.

## Useful commands

```bash
./wifi_air_suite.sh --help
./wifi_air_suite.sh --version
./wifi_air_suite.sh --show-paths
./wifi_air_suite.sh --update-oui
./wifi_air_suite.sh --print-config
./wifi_air_suite.sh --list-captures
./wifi_air_suite.sh --list-csv
./wifi_air_suite.sh --clean-tmp
./wifi_air_suite.sh --purge
```

Use active wireless actions only on networks/devices you own or are explicitly authorized to test.
