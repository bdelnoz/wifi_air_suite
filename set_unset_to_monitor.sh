#!/usr/bin/env bash
set -u
IFS=$'\n\t'

say()  { printf '%s\n' "$*"; }
info() { printf '[*] %s\n' "$*"; }
ok()   { printf '[OK] %s\n' "$*"; }
err()  { printf '[KO] %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

usage() {
    cat <<'USAGE'
Usage:
  ./set_unset_to_monitor.sh [interface] [set|unset]

Examples:
  ./set_unset_to_monitor.sh wlan0 set
  ./set_unset_to_monitor.sh wlan0 unset

Defaults:
  interface : wlan0
  action    : unset
USAGE
}

IFACE="${1:-wlan0}"
ACTION="${2:-unset}"

case "$IFACE" in
    -h|--help) usage; exit 0 ;;
esac

[[ "$IFACE" =~ ^wlan[0-9]+$ ]] || die "Interface invalide : $IFACE (attendu: wlanX)"
[[ "$ACTION" == "set" || "$ACTION" == "unset" ]] || die "Action invalide : $ACTION (set|unset)"

for cmd in ip iw; do
    command -v "$cmd" >/dev/null 2>&1 || die "Commande manquante : $cmd"
done

run_root() {
    if (( EUID == 0 )); then
        "$@"
    else
        command -v sudo >/dev/null 2>&1 || die "sudo est requis pour cette opération."
        sudo "$@"
    fi
}

iface_exists() { iw dev "$IFACE" info >/dev/null 2>&1; }
iface_exists || die "Interface introuvable : $IFACE"

if [[ "$ACTION" == "set" ]]; then
    info "Passage en mode monitor : $IFACE"
    if command -v nmcli >/dev/null 2>&1; then
        run_root nmcli device set "$IFACE" managed no >/dev/null 2>&1 || true
    fi
    run_root ip link set "$IFACE" down
    run_root iw dev "$IFACE" set type monitor
    run_root ip link set "$IFACE" up
    TYPE="$(iw dev "$IFACE" info 2>/dev/null | awk '$1 == "type" {print $2; exit}')"
    [[ "$TYPE" == "monitor" ]] || die "Échec du passage en monitor : type actuel=${TYPE:-inconnu}"
    ok "$IFACE est en mode monitor."
    exit 0
fi

info "Retour en mode managed : $IFACE"
run_root ip link set "$IFACE" down
run_root iw dev "$IFACE" set type managed
run_root ip link set "$IFACE" up
if command -v nmcli >/dev/null 2>&1; then
    run_root nmcli device set "$IFACE" managed yes >/dev/null 2>&1 || true
fi
TYPE="$(iw dev "$IFACE" info 2>/dev/null | awk '$1 == "type" {print $2; exit}')"
[[ "$TYPE" == "managed" ]] || die "Échec du retour en managed : type actuel=${TYPE:-inconnu}"
ok "$IFACE est en mode managed."
