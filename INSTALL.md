# wifi_air_suite — Installation

Version: **v2.1.4**

## 1. Package layout

Keep these scripts beside each other:

```text
wifi_air_suite.sh
set_unset_to_monitor.sh
```

The main script resolves the monitor helper from its own directory.

## 2. Permissions

```bash
chmod +x wifi_air_suite.sh set_unset_to_monitor.sh
```

## 3. Check/install prerequisites

```bash
./wifi_air_suite.sh --prerequis
```

To install the supported prerequisite set through APT:

```bash
./wifi_air_suite.sh --install
```

The script handles its own sudo authentication for operational work; invoking the complete script with external `sudo` is supported but not required.

## 4. Initialize runtime directories

```bash
./wifi_air_suite.sh --init
```

Default layout:

```text
.results/{cap,csv,filtered,enriched,generated,logs,tmp,archive}
```

## 5. Configure local data

### Exclusions

Edit:

```text
myinfo/exclusions.txt
```

Place one MAC address at the beginning of each relevant line. MACs found in the exclusion file are removed from filtered results.

### OUI/manufacturer database

The package contains a placeholder:

```text
myinfo/oui.txt
```

Populate/update it automatically from the IEEE Registration Authority public MA-L/OUI listing:

```bash
./wifi_air_suite.sh --update-oui
```

Preview the update without changing anything:

```bash
./wifi_air_suite.sh --simulate --update-oui
```

The previous file is kept as `myinfo/oui.txt.bak`. Failed downloads or validation failures leave the current database untouched. `curl` is installed by the supported APT prerequisite set; `wget` can also be used as a fallback.

If the file is empty or unavailable, capture still works; manufacturer enrichment will be unavailable or return `Unknown`.

## 6. Validate installation

```bash
./wifi_air_suite.sh --version
./wifi_air_suite.sh --show-paths
./wifi_air_suite.sh --doctor
./wifi_air_suite.sh --simulate --update-oui
./wifi_air_suite.sh --simulate --capture --interface wlan0 --duration 20 --post-process --nolog
```

The simulation command performs no privileged/system/network change.

## 7. Common capture commands

Normal logging:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 --post-process
```

No persistent logs:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --duration 3600 --interval 10 --post-process --nolog
```

Target one BSSID on a known channel:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --bssid C6:4F:D5:24:D3:1E --channel 4 \
  --duration 300 --post-process --nolog
```

Infinite interval capture without persistent logs:

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0 \
  --infinite --interval 10 --post-process --accept --nolog
```

## 8. Disk-space note

`--nolog` prevents new persistent `.log` files for that invocation. It does not delete logs already present in `.results/logs/`, and it does not disable CAP/CSV or post-processing outputs.
