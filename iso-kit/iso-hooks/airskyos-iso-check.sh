#!/bin/sh
# remove from airootfs!
# Prints AIRSKYOS-ISO-CHECK-FAILED (picked up by 04-build-iso.sh) when a
# program the live ISO needs cannot find one of its libraries.
failed=0
for bin in /usr/bin/calamares /usr/bin/plasmashell /usr/bin/kwin_wayland; do
    [ -x "$bin" ] || continue
    missing=$(ldd "$bin" 2>/dev/null | awk '/not found/ {print $1}' | tr '\n' ' ')
    if [ -n "$missing" ]; then
        echo "AIRSKYOS-ISO-CHECK-FAILED: $bin cannot find: $missing"
        failed=1
    fi
done
[ $failed = 0 ] && echo "AirSkyOS ISO check: installer and desktop libraries OK"
exit 0
