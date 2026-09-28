# AirSkyOS ISO kit - shared settings (sourced by the numbered scripts)

# Working directory (needs ~20 GB free)
WORK="${WORK:-$HOME/airskyos-iso}"

# CachyOS archiso profile this kit builds on
CACHYOS_ISO_GIT="https://github.com/CachyOS/CachyOS-Live-ISO.git"
CACHYOS_CALAMARES_GIT="https://github.com/CachyOS/cachyos-calamares.git"
CACHYOS_CALAMARES_BRANCH="cachyos-dev"

# ISO labels
DISTRO_NAME="AirSkyOS"
ISO_PUBLISHER="Aozora <https://aozora9200.f5.si/>"
ISO_APPLICATION="AirSkyOS Live/Install"
ISO_LABEL_PREFIX="AIRSKY"          # + _YYYYMM, max 32 chars in total

# Where 02-build-localrepo.sh looks for built packages (AUR / your own).
# Extra directories can also be passed as arguments.
PKG_SEARCH_DIRS=(
    /var/cache/pacman/pkg
    "$HOME/.cache/paru/clone"
    "$HOME/.cache/yay"
    "$HOME/airskyos-pkgbuild"
    "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/packages"   # this repository
)

# Never put these on the ISO (in addition to exclude-packages.txt):
#  - CachyOS Hello: replaced by airskyos-release
#  - CachyOS CLI installer: installs a plain CachyOS from the internet
ALWAYS_EXCLUDE=(
    cachyos-hello cachyos-hello-git
    cachyos-cli-installer-new cachyos-cli-installer-new-git
)

# Always put these on the ISO: the installer (offline mode) sets up Limine by
# default, so Limine and its kernel hook must already be on the ISO.
# airskyos-welcome is the first screen of the live ISO (with an install button).
ALWAYS_INCLUDE=(
    limine limine-mkinitcpio-hook efibootmgr
    airskyos-welcome
)

# all excluded package names, one per line
excluded_packages() {
    printf '%s\n' "${ALWAYS_EXCLUDE[@]}"
    sed 's/#.*//; s/[[:space:]]//g' "$KIT_DIR/exclude-packages.txt" 2>/dev/null | grep -v '^$' || true
}

EXPORT="$WORK/export"
LOCALREPO="$WORK/localrepo"
LOCALREPO_NAME="airskyos-local"
ISOSRC="$WORK/cachyos-live-iso"
PROFILE="$ISOSRC/archiso"
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

msg()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2; exit 1; }
