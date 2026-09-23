# wifi_air_suite — Specifications

Version: **v2.1.4**  
Main script: `wifi_air_suite.sh`  
Monitor helper: `set_unset_to_monitor.sh`

## 1. Execution contract

The CLI separates authorization from the requested business action.

Real operational execution:

```text
--exec --<business-action>
```

Simulation:

```text
--simulate --<business-action>
```

`--exec` and `--simulate` are mutually exclusive. Exactly one business action is accepted per invocation.

## 2. Business actions

| Action | Purpose |
|---|---|
| `--capture` | Capture with `airodump-ng` only |
| `--check` | Inspect a selected/latest capture with bounded `aircrack-ng` |
| `--crack` | Explicit wordlist crack; requires `--wordlist` and `--bssid` |
| `--attack-hosts` | Authorized/lab deauthentication from AP/station CSV pairs |
| `--attack-preauth` | Authorized/lab fake-authentication from AP/station CSV pairs |
| `--test-injection` | Authorized/lab `aireplay-ng --test` |

## 3. Maintenance actions

| Action | Purpose | `--exec` required |
|---|---|---|
| `--prerequis` / aliases | Check supported prerequisites | No |
| `--install` | Install supported APT package set | No |
| `--doctor` | Print paths, prerequisites, interfaces and runtime inventory | No |
| `--init` | Create expected local/runtime layout | No |
| `--update-oui` | Refresh `myinfo/oui.txt` from IEEE MA-L/OUI public data | No |
| `--show-paths` | Print resolved paths | No |
| `--print-config` | Print resolved configuration | No |
| `--list-captures` | List capture files | No |
| `--list-csv` | List CSV files | No |
| `--clean-tmp` | Clean runtime temp files | No |
| `--purge` / `--clean-runtime` | Purge managed runtime artifacts | No |
| `--stop` | Stop the active registered invocation | No |

### OUI update contract

`--update-oui` uses the IEEE Registration Authority MA-L/OUI public text listing by default:

```text
https://standards-oui.ieee.org/oui/oui.txt
```

Update sequence:

1. create/resolve `.results/tmp/`;
2. download with `curl`, or `wget` if curl is unavailable;
3. extract IEEE `(hex)` MA-L rows;
4. normalize to `AA:BB:CC<TAB>Manufacturer`;
5. require at least 10,000 valid entries;
6. write metadata headers;
7. copy the current `myinfo/oui.txt` to `myinfo/oui.txt.bak`;
8. install the validated new file.

A failed download or validation never replaces the current database. The environment variable `WIFI_AIR_SUITE_OUI_URL` can override the source for testing or a mirror.

## 4. Capture timing

`--duration SECONDS` defines a finite capture duration. Timed captures use GNU `timeout` with `SIGINT` first and a `SIGKILL` fallback after 3 seconds.

`--infinite` forces an unlimited session.

`--interval MINUTES` splits capture into independent slices. Every interval receives a new collision-safe timestamp prefix and normal `-01.cap` / `-01.csv` outputs. With finite duration, the last slice uses the remaining seconds when needed.

Monitor mode is entered once for the complete capture session and preserved between interval slices.

## 5. Targeted channel capture

`--channel N` is available only with `--capture` and requires `--bssid MAC`. The channel value must belong to the same supported channel set used by the default capture engine.

When supplied, `airodump-ng` is started with that single channel instead of the default multi-channel list. When omitted, the existing multi-channel behavior is preserved.

Example:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --bssid C6:4F:D5:24:D3:1E --channel 4 \
  --duration 300 --post-process --nolog
```

## 6. Post-processing

`--post-process` processes each completed capture slice and produces:

- copied raw CSV in `.results/csv/`;
- filtered CSV in `.results/filtered/`;
- filtered Markdown in `.results/filtered/`;
- OUI-enriched CSV in `.results/enriched/`;
- copies of generated artifacts in `.results/generated/`.

`--open-kate` requires `--post-process` and opens each generated filtered Markdown asynchronously.

## 7. Logging modes

### Default mode

Persistent logs are enabled. A capture slice can create:

```text
.results/logs/<prefix>.log
.results/logs/airodump-<prefix>.log
```

Action operations use their corresponding action log path.

Live capture without spinner uses util-linux `script` to provide a PTY while mirroring the terminal session to the airodump log.

### `--nolog` / `--no-log`

v2.1.2 adds an explicit no-persistent-log mode.

Internally, log sinks are redirected to `/dev/null`. Therefore:

- no persistent global log is created;
- no persistent airodump terminal log is created;
- no persistent action log is created;
- capture and post-processing artifacts are unchanged;
- live capture runs directly on the real terminal instead of through the logging PTY;
- spinner mode discards airodump terminal output to `/dev/null` while retaining the spinner;
- existing logs are untouched.

`--nolog` does not mean “no results”; it only disables `.log` persistence.

## 8. Runtime paths

Default runtime root:

```text
.results/
```

Subdirectories:

```text
cap/
csv/
filtered/
enriched/
generated/
logs/
tmp/
archive/
```

The runtime root can be overridden with `--dest_dir DIR` or `--dest-dir DIR`.

## 9. Selection and filtering

- `-o, --offset N` selects the Nth newest capture/CSV where supported.
- `--all` selects all supported CSV files.
- `--cap-file FILE` selects an explicit capture.
- `--csv-file FILE` selects an explicit CSV.
- `-b, --bssid MAC` applies a BSSID filter.
- `--channel N` restricts a BSSID-targeted capture to one supported Wi-Fi channel; capture-only and requires `--bssid`.
- `--station MAC` applies a station filter.
- `-X, --exclusions-file FILE` overrides the MAC exclusion file.
- `-w, --wordlist FILE` supplies the explicit crack wordlist.

## 10. Monitor helper contract

The main script resolves the helper from the same repository directory:

```bash
MONITOR_HELPER="$BASE_DIR/set_unset_to_monitor.sh"
```

Expected calls:

```bash
./set_unset_to_monitor.sh wlan0 set
./set_unset_to_monitor.sh wlan0 unset
```

The helper accepts `wlanX`, changes the interface between monitor and managed types, and coordinates NetworkManager ownership when `nmcli` is available.

## 11. Prerequisites

The script checks for the tools it needs according to the action. Core supported packages include Aircrack-ng, util-linux, `iw`, wireless-tools, NetworkManager and standard GNU utilities.

Use:

```bash
./wifi_air_suite.sh --prerequis
./wifi_air_suite.sh --install
```

## 12. Safety boundary

Active `aireplay-ng` actions are explicitly documented as owned/authorized lab operations. Capture remains a separate action and does not implicitly launch an active attack.
