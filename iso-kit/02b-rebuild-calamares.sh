#!/usr/bin/env bash
# 2b. Rebuild the installer (cachyos-calamares-next) against the libraries
#     that are in the repositories right now, and put it into the local repo.
#
#     Needed when the repository's installer was built against an older
#     library than the one the ISO gets, e.g.
#       calamares: error while loading shared libraries:
#       libboost_python314.so.1.91.0: cannot open shared object file
#     (Arch moved boost to a new version, the installer was not rebuilt yet).
#     The local repository comes first in the build pacman.conf, so this copy
#     replaces the repository one on the ISO.
#
#     Run as your normal user (makepkg asks for sudo to install build deps).
set -euo pipefail
. "$(dirname "$0")/config.sh"
trap 'die "stopped at line $LINENO: $BASH_COMMAND"' ERR

((EUID != 0)) || die "run as a normal user, not root"
[[ -d $LOCALREPO ]] || die "run 02-build-localrepo.sh first"

dir="$WORK/cachyos-calamares-build"
msg "Fetching the CachyOS installer PKGBUILD"
rm -rf "$dir"
git clone -q --depth 1 --filter=blob:none --sparse https://github.com/CachyOS/CachyOS-PKGBUILDS "$dir"
git -C "$dir" sparse-checkout set cachyos-calamares
cd "$dir/cachyos-calamares"

# mark it as a local rebuild (and newer than the repository build)
sed -i -E 's/^pkgrel=([0-9]+)$/pkgrel=\1.1/' PKGBUILD
grep -m1 '^pkgname=' PKGBUILD; grep -m1 '^pkgver=' PKGBUILD; grep -m1 '^pkgrel=' PKGBUILD

msg "Building (10-30 min)"
makepkg -s --noconfirm --needed -f

shopt -s nullglob
built=(cachyos-calamares-next-*.pkg.tar.zst)
((${#built[@]})) || die "no package was built"
rm -f "$LOCALREPO"/cachyos-calamares-next-*.pkg.tar.zst
cp -f "${built[@]}" "$LOCALREPO/"
chmod a+r "$LOCALREPO"/cachyos-calamares-next-*.pkg.tar.zst

msg "Updating the local repository database"
repo-add -q -R "$LOCALREPO/$LOCALREPO_NAME.db.tar.gz" "$LOCALREPO"/cachyos-calamares-next-*.pkg.tar.zst

# quick check: which boost does the new installer need?
need=$(bsdtar -xOf "${built[0]}" usr/bin/calamares 2>/dev/null | strings | grep -m1 -o 'libboost_python[0-9]*\.so\.[0-9.]*' || true)
have=$(pacman -Si boost-libs 2>/dev/null | awk -F': ' '/^Version/ {print $2; exit}')
printf '  installer needs: %s\n  repository boost-libs: %s\n' "${need:-?}" "${have:-?}"
msg "Done. Now run ./03-prepare-profile.sh and ./04-build-iso.sh"
