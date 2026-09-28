#!/usr/bin/env bash
# 4. Build the ISO (asks for sudo; takes 20-60 min).
set -euo pipefail
. "$(dirname "$0")/config.sh"
trap 'die "stopped at line $LINENO: $BASH_COMMAND"' ERR

[[ -d $PROFILE ]] || die "run 03-prepare-profile.sh first"
need=(archiso mkinitcpio-archiso git squashfs-tools grub)
missing=()
for p in "${need[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done
if ((${#missing[@]})); then
    msg "Installing build tools: ${missing[*]}"
    sudo pacman -S --needed "${missing[@]}"
fi

cd "$ISOSRC"
log="$WORK/build.log"
rm -f "$log.failed"
sudo ./buildiso.sh -p desktop -v -w 2>&1 | tee "$log" || true
# mkarchiso runs as root: give the results back to you so you can move/delete them
sudo chown -R "$(id -u):$(id -g)" "$ISOSRC/out" 2>/dev/null || true
sudo rm -rf "$ISOSRC/build" 2>/dev/null || true

# --- checks printed by the ISO build hooks --------------------------------
problems=$(grep -E 'AIRSKYOS-ISO-CHECK-FAILED' "$log" | sort -u || true)
if ! grep -q 'AIRSKYOS-INSTALLER-OK' "$log"; then
    problems+=$'\n'"AIRSKYOS-ISO-CHECK-FAILED: the AirSkyOS installer setup did not run (installer would be CachyOS)"
fi
if [[ -n ${problems//[[:space:]]/} ]]; then
    printf '%s\n' "$problems" | sed '/^$/d; s/^/  /'
    warn "the ISO is NOT ready to ship (see above)."
    cat <<HINT
  - "cannot find ..." : rebuild the installer:  ./02b-rebuild-calamares.sh
  - "installer is not AirSkyOS" / "did not run": make sure you use this kit's
    03-prepare-profile.sh (it copies live/ and iso-hooks/ into the profile),
    then run ./03-prepare-profile.sh && ./04-build-iso.sh again.
HINT
    exit 1
fi

msg "ISO:"
ls -lh "$ISOSRC"/out/desktop/*.iso
msg "build log: $log"
