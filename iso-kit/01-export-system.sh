#!/usr/bin/env bash
# 1. Record what the finished AirSkyOS machine consists of.
#    Run as your normal user on the AirSkyOS PC. Nothing personal is exported:
#    only package names, enabled services and the names of changed /etc files.
set -euo pipefail
. "$(dirname "$0")/config.sh"
trap 'die "stopped at line $LINENO: $BASH_COMMAND"' ERR

mkdir -p "$EXPORT"
cd "$EXPORT"

msg "Packages installed explicitly from repositories"
pacman -Qqen | sort >pkgs-repo.txt
msg "Packages not in any repository (AUR, AirSkyOS local builds)"
pacman -Qqem | sort >pkgs-foreign.txt
pacman -Qm >pkgs-foreign-versions.txt

msg "Enabled systemd services (for reference)"
systemctl list-unit-files --state=enabled --no-legend 2>/dev/null |
    awk '{print $1}' | sort >services-enabled.txt

msg "Config files in /etc you changed from the package defaults"
pacman -Qii 2>/dev/null | awk '/^MODIFIED/ {print $2}' | sort >etc-modified.txt

if command -v pacreport >/dev/null 2>&1; then
    msg "Files in /etc not owned by any package (pacutils)"
    pacreport --unowned-files 2>/dev/null | awk '$1 ~ "^/etc/" {print $1}' >etc-unowned.txt || true
else
    warn "pacreport not found (pacman -S pacutils) - skipping the unowned-file report"
fi

cp /etc/os-release os-release.current 2>/dev/null || true
[[ -f /usr/share/airskyos/os-release ]] && cp /usr/share/airskyos/os-release os-release.airskyos

cat <<INFO

  $(wc -l <pkgs-repo.txt) repo packages, $(wc -l <pkgs-foreign.txt) foreign packages -> $EXPORT
  Review:
    pkgs-foreign.txt      these need package files (next step)
    etc-modified.txt      copy settings you want to ship into the profile's airootfs/
    etc-unowned.txt       same, for files no package owns
    services-enabled.txt  copy the ones you want into extra-services.txt

INFO
