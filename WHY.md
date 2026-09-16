<!--
DOCUMENT INFORMATION
Document Name: WHY.md
Author: Bruno DELNOZ
Email: bruno.delnoz@protonmail.com
Version: v2.1.1
Date / Time: 2026-09-16 03:05
Project: Package scan WIFI / wifi_air_suite.sh
Short description: Design rationale and compatibility decisions for the current implementation.
-->
# WHY — wifi_air_suite.sh — v2.1.1

## Why a major version

Version 2.0.0 introduces a new capture execution model: one logical capture session can contain multiple independent `airodump-ng` slices.

That changes the workflow enough to justify a major version while preserving the existing CLI, directories and output formats.


## Why the monitor helper now lives beside the main script

The project is now a standalone public repository. Keeping `set_unset_to_monitor.sh` beside `wifi_air_suite.sh` removes the old dependency on a parent-project `tools/monitor/` tree and makes the repository self-contained. The main script therefore resolves the helper relative to its own directory with `$BASE_DIR/set_unset_to_monitor.sh`.

## Why filtered Markdown exists

The filtered CSV remains the machine-oriented reference output, but it is not pleasant to inspect repeatedly in a text editor. v2.1.0 therefore creates a Markdown representation from the **already-filtered CSV**. This avoids a second filtering implementation and guarantees that CSV and Markdown are based on the same selected rows.

## Why `--open-kate` is optional

Opening an editor is a desktop convenience, not a capture requirement. The default remains headless-compatible. When `--open-kate` is explicitly supplied together with `--post-process`, the newly generated Markdown is opened asynchronously, so the next interval is not blocked by the editor.

## Why `--interval` exists

Long single captures delay finalized result sets.

The interval model produces regular finalized CSV/CAP checkpoints.

```text
1 hour total
10-minute interval
= 6 independent result sets
```

## Why every interval gets a new prefix

Reusing the same prefix could overwrite or mix previous interval output.

Each slice therefore calls the existing collision-safe prefix generator.

Normal naming is preserved:

```text
<PREFIX>-01.csv
<PREFIX>-01.cap
```

## Why monitor mode is not toggled every interval

The restart concerns the capture process, not the physical interface configuration.

Monitor mode is entered once for the logical capture session. Only `airodump-ng` is stopped/restarted at interval boundaries.

## Why post-process runs before the next slice

The intended sequence is:

```text
capture slice
→ finalize CSV
→ post-process exact CSV
→ next slice
```

This makes every interval independently usable and avoids selecting the wrong CSV by offset.

## Why post-process failure does not stop capture

The raw acquisition session is more important than one failed filter/enrichment step.

A post-process error is warned and the following interval continues.

## Why `--duration` stays in seconds

Older releases already defined `--duration SECONDS`.

Changing that unit would silently break existing commands.

Therefore:

```text
--duration = seconds
--interval = minutes
```

## Why the final interval can be shorter

The total duration must not be exceeded.

```text
1250 seconds total
10-minute interval
→ 600 + 600 + 50
```

## Why `--accept` exists

`--accept` is recognized for non-interactive CLI compatibility.

It does not bypass sudo and currently does not auto-answer any capture prompt because the current CAPTURE path has no ordinary confirmation prompt.

## Why `--post-process` remains explicit

Interval slicing does not automatically enable processing.

Without `--post-process`, the script captures only.

With it, processing runs after every completed interval.

## Why CAPTURE still never runs CHECK or CRACK

Action separation remains a core anti-regression contract.

`--capture` acquires data only.

CHECK and CRACK remain explicit separate actions.

## Why PTY capture is retained

`airodump-ng` needs a terminal to render its normal live table reliably.

The util-linux `script` PTY method is preserved for non-spinner capture.

## Why the runtime layout is unchanged

Existing workflows already consume:

```text
.results/cap/
.results/csv/
.results/filtered/
.results/enriched/
.results/generated/
.results/logs/
.results/tmp/
.results/archive/
```

The v2 feature changes scheduling, not storage contracts.
