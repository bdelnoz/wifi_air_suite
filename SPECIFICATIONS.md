<!--
DOCUMENT INFORMATION
Document Name: SPECIFICATIONS.md
Author: Bruno DELNOZ
Email: bruno.delnoz@protonmail.com
Version: v2.0.0
Date / Time: 2026-09-16 02:30
Project: Package scan WIFI / wifi_air_suite.sh
Short description: Task-scoped specification for v2.0.0 interval capture and per-slice post-processing.
-->
# SPECIFICATIONS — Interval Capture — v2.0.0

## 1. Purpose
Add periodic CAPTURE slicing so one long logical session produces independent finalized result sets at the requested interval.

## 2. Scope
This task adds `--interval MINUTES`, `--accept`, and per-slice scheduling of existing post-processing.

## 3. Existing behavior to preserve

- `--duration` is seconds.
- omitted duration or `--infinite` allows continuous capture.
- CAPTURE uses `airodump-ng`.
- normal capture uses collision-safe prefixes.
- normal outputs are `PREFIX-01.csv` and `PREFIX-01.cap`.
- `--post-process` copies raw CSV, filters exclusions and attempts OUI enrichment.
- runtime is `.results/`.
- timed stop uses SIGINT plus hard fallback.
- live mode uses PTY.
- CAPTURE never launches `aircrack-ng`.

## 4. Functional requirements

### FR-1 — `--interval MINUTES`
Positive integer, CAPTURE-only.

### FR-2 — duration compatibility
`--duration` remains seconds.

### FR-3 — finite slicing
Each slice duration is `min(interval_seconds, remaining_seconds)`.

Examples:
`3600 + interval 10` → `600 x 6`.
`1250 + interval 10` → `600 + 600 + 50`.

### FR-4 — infinite slicing
With interval and no finite duration, repeat until interruption.

### FR-5 — unique prefix
Every slice calls the existing collision-safe prefix generator and writes its own `-01.csv` and `-01.cap`.

### FR-6 — post-process per slice
With `--post-process`, process the exact CSV of the completed slice before starting the next slice.

### FR-7 — output naming
Keep established `csv/`, `filtered/`, `enriched/`, `generated/` naming.

### FR-8 — processing failure
Warn/log and continue future capture slices.

### FR-9 — monitor continuity
Enter monitor mode once before the loop; keep it between slices; cleanup at final termination if this script changed it.

### FR-10 — archive-old
Run once before the first slice only.

### FR-11 — `--accept`
Accept the option, set compatibility state, never bypass sudo.

### FR-12 — no-interval compatibility
Without interval, preserve previous single-capture scheduling.

### FR-13 — action isolation
No interval boundary triggers CHECK, CRACK or ATTACK.

## 5. Non-functional requirements

- preserve `.results/`;
- preserve filenames within each slice;
- preserve PTY/spinner behavior;
- preserve sudo behavior;
- avoid overwrite;
- show slice index, duration and processing state.

## 6. Inputs

```text
--interval MINUTES
--accept
--duration SECONDS
--infinite
--post-process
--no-post-process
--archive-old
--spinner
--no-spinner
--interface IFACE
```

## 7. Outputs
No new output format. One existing-format result set per interval.

## 8. Files and directories concerned

```text
wifi_air_suite.sh
.results/cap/
.results/csv/
.results/filtered/
.results/enriched/
.results/generated/
.results/logs/
.results/tmp/
.results/archive/
myinfo/exclusions.txt
myinfo/oui.txt
```

## 9. Primary commands

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0   --duration 3600 --interval 10 --post-process --accept
```

```bash
./wifi_air_suite.sh --simulate --capture --interface wlan0   --duration 3600 --interval 10 --post-process --accept
```

```bash
./wifi_air_suite.sh --exec --capture --interface wlan0   --infinite --interval 10 --post-process --accept
```

## 10. Constraints and safety

- reject zero/negative/non-integer interval;
- reject interval outside CAPTURE;
- `--accept` never disables sudo;
- CAPTURE never implicitly checks/cracks/attacks;
- authorized/lab boundary unchanged.

## 11. Validation and acceptance criteria

1. `bash -n` succeeds.
2. help documents interval and accept.
3. simulation reports interval=10, post-process=1, accept=1.
4. 3600/10m resolves to six 600-second slices.
5. 1250/10m resolves to 600,600,50.
6. slices use distinct prefixes.
7. slices get independent raw CSV/CAP.
8. processed outputs are per slice when enabled.
9. processing error does not cancel later slices.
10. no-interval behavior remains compatible.

## 12. Out of scope

Changing CAP/CSV formats, changing `.results/`, changing duration unit, automatically enabling post-process, bypassing sudo, or auto-running CHECK/CRACK.

## 13. Changelog

### v2.0.0 — 2026-09-16
- Added interval capture.
- Added unique per-slice prefixes.
- Added duration remainder handling.
- Added infinite rolling slices.
- Added per-slice post-process.
- Added `--accept` parser compatibility.
- Preserved no-interval behavior.

### v1.0.13-SOLO414 baseline
Live PTY display, bounded timed stop and corrected sudo/PTY behavior were the immediate pre-v2 baseline.
