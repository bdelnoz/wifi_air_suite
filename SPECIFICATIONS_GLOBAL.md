<!--
DOCUMENT INFORMATION
Document Name: SPECIFICATIONS_GLOBAL.md
Author: Bruno DELNOZ
Email: bruno.delnoz@protonmail.com
Version: v2.0.0
Date / Time: 2026-09-16 02:30
Project: Package scan WIFI / wifi_air_suite.sh
Short description: Stable global requirements and contracts for the wifi_air_suite.sh project.
-->
# SPECIFICATIONS_GLOBAL — wifi_air_suite.sh — v2.0.0

## 1. Purpose
Define stable project-wide behavior that task-scoped changes must preserve unless explicitly superseded.

## 2. Global scope
The durable operational entry point is `wifi_air_suite.sh`. It supports capture, check, explicit crack, authorized/lab actions, runtime management, filtering and OUI enrichment.

## 3. Stable verified behavior

### 3.1 Execution gate
Real operational actions require `--exec`; simulations use `--simulate`.

### 3.2 Action separation
Exactly one business action is selected from:
`--capture`, `--check`, `--crack`, `--attack-hosts`, `--attack-preauth`, `--test-injection`.

CAPTURE never implicitly triggers CHECK, CRACK or ATTACK.

### 3.3 Capture
CAPTURE uses `airodump-ng` and supports finite seconds, infinite mode, interval slicing in minutes, PTY live display, optional spinner, optional post-processing, collision-safe prefixes, monitor helper integration and internal sudo handling.

### 3.4 Check
CHECK is bounded and non-interactive.

### 3.5 Crack
CRACK requires explicit BSSID and wordlist.

## 4. Repository architecture

```text
cmd.analyse.airo.sniff/
├── wifi_air_suite.sh
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

## 5. Global functional requirements

1. Filename remains `wifi_air_suite.sh`.
2. No arguments display help only.
3. Real operational actions require `--exec`.
4. Simulation does not require `--exec`.
5. CAPTURE never launches `aircrack-ng`.
6. `--duration` remains seconds.
7. `--interval` is minutes and CAPTURE-only.
8. Every interval uses a fresh collision-safe prefix.
9. Every interval writes normal `airodump-ng` CSV/CAP outputs.
10. `--post-process` remains explicit.
11. With intervals, post-process runs after each completed slice.
12. Post-process failure does not abort future slices.
13. Final finite slice uses only remaining requested seconds.
14. Infinite interval mode loops until interruption.
15. `--accept` is parser-compatible and never bypasses sudo.
16. Monitor mode is entered once for the logical capture session and preserved between slices.
17. Runtime paths remain compatible.
18. Existing processed-output naming remains compatible.
19. Behavior without `--interval` remains compatible.

## 6. Global non-functional requirements

- No silent overwrite of prior slices.
- Preserve live PTY display when spinner is off.
- Preserve bounded SIGINT/SIGKILL timed stop.
- Never read/store sudo password in the script.
- Preserve understandable logs and execution summaries.

## 7. Global inputs

```text
CLI arguments
Wi-Fi interface
myinfo/exclusions.txt
myinfo/oui.txt
optional CAP/CSV paths
optional wordlist
```

## 8. Global outputs

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

## 9. Global interfaces and commands

Control/info actions include `--help`, `--exec`, `--simulate`, `--prerequis`, `--install`, `--stop`, `--changelog`, `--purge`, `--doctor`, `--init`, `--show-paths`, `--print-config`, `--list-captures`, `--list-csv`, `--clean-tmp`, `--version`.

Key CAPTURE options include `--interface`, `--duration`, `--infinite`, `--interval`, `--post-process`, `--no-post-process`, `--accept`, `--archive-old`, `--spinner`, `--no-spinner`, `--exclusions-file`, `--dest_dir`.

## 10. Constraints and safety rules

- Attack actions are only for owned/authorized environments.
- CAPTURE remains acquisition-only.
- `--accept` never disables sudo authentication.
- Post-process operates on the exact CSV of the completed slice.
- Runtime purge does not remove source/docs or `myinfo/`.

## 11. Global validation and acceptance criteria

- `bash -n wifi_air_suite.sh` succeeds.
- `--help` matches parser behavior.
- `--version` matches the release.
- capture simulation parses interval/post-process/accept.
- no-interval capture preserves previous scheduling.
- finite interval mode does not exceed total duration.
- intervals use distinct prefixes.
- post-process is per interval when enabled.
- runtime layout is unchanged.

## 12. Task-scoped boundary
Feature-specific requirements belong in `SPECIFICATIONS.md`.

## 13. Out of scope
External Git workflow, hardware RF performance, third-party driver bugs, and authorization for networks not owned/controlled by the operator.

## 14. Changelog

### v2.0.0 — 2026-09-16
- Added interval capture to the stable contract.
- Added per-interval post-processing.
- Added `--accept` compatibility semantics.
- Preserved v1 action/runtime separation.

### v1.0.9-SOLO414 baseline
- Established canonical execution/simulation gates.
- Established action separation and `.results/`.
- Established the four-file specification model.
