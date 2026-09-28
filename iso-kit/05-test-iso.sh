#!/usr/bin/env bash
# 5. Boot the newest ISO in a virtual machine (UEFI) with a 40 GB test disk.
#    Needs: qemu-desktop edk2-ovmf
set -euo pipefail
. "$(dirname "$0")/config.sh"
trap 'die "stopped at line $LINENO: $BASH_COMMAND"' ERR

iso=$(ls -t "$ISOSRC"/out/desktop/*.iso 2>/dev/null | head -n1)
[[ -n $iso ]] || die "no ISO found - run 04-build-iso.sh"
disk="$WORK/test-disk.qcow2"
[[ -f $disk ]] || qemu-img create -f qcow2 "$disk" 40G
[[ -f /usr/share/edk2/x64/OVMF_CODE.4m.fd ]] || die "install edk2-ovmf"
[[ -f $WORK/OVMF_VARS.fd ]] || cp /usr/share/edk2/x64/OVMF_VARS.4m.fd "$WORK/OVMF_VARS.fd"

msg "Booting $iso"
exec qemu-system-x86_64 -enable-kvm -machine q35 -cpu host -smp 4 -m 8G \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
    -drive if=pflash,format=raw,file="$WORK/OVMF_VARS.fd" \
    -device virtio-vga-gl -display gtk,gl=on \
    -audiodev pipewire,id=snd -device ich9-intel-hda -device hda-output,audiodev=snd \
    -drive file="$disk",if=virtio \
    -cdrom "$iso" -boot d
