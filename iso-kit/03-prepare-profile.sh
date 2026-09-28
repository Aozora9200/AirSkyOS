#!/usr/bin/env bash
# 3. Turn a fresh copy of CachyOS's archiso profile into the AirSkyOS profile.
#    Safe to run again: it always starts from a clean checkout.
set -euo pipefail
. "$(dirname "$0")/config.sh"
trap 'die "stopped at line $LINENO: $BASH_COMMAND"' ERR

[[ -f $EXPORT/pkgs-repo.txt ]] || die "run 01-export-system.sh first"
[[ -f $LOCALREPO/$LOCALREPO_NAME.db ]] || die "run 02-build-localrepo.sh first"
command -v git >/dev/null || die "git is required"

msg "AirSkyOS ISO kit $(cat "$KIT_DIR/VERSION" 2>/dev/null || echo '(unknown version)')"
[[ -x $KIT_DIR/live/airskyos-installer-setup && -x $KIT_DIR/live/airskyos-target-setup && -f $KIT_DIR/live/airskyos-finish && -f $KIT_DIR/live/airskyos-removeun ]] || die "this kit is incomplete (live/airskyos-installer-setup missing) - extract the whole kit again"

# --- fresh CachyOS profile ------------------------------------------------
msg "Fetching the CachyOS archiso profile"
# keep finished ISOs; earlier builds may have left root-owned files behind
if [[ -d $ISOSRC/out ]]; then
    mkdir -p "$WORK/iso-out"
    sudo chown -R "$(id -u):$(id -g)" "$ISOSRC/out"
    find "$ISOSRC/out" -type f \( -name '*.iso' -o -name '*.sha256' -o -name '*.pkgs.txt' \) -exec mv -n {} "$WORK/iso-out/" \;
fi
rm -rf "$ISOSRC" 2>/dev/null || sudo rm -rf "$ISOSRC"
git clone --depth 1 "$CACHYOS_ISO_GIT" "$ISOSRC"
AIROOT="$PROFILE/airootfs"

# --- package list ---------------------------------------------------------
msg "Package list: CachyOS live set + everything on your AirSkyOS PC"
clean() { sed 's/#.*//; s/[[:space:]]//g' "$@" | grep -v '^$'; }
{
    clean "$PROFILE/packages_desktop.x86_64"
    clean "$EXPORT/pkgs-repo.txt" "$EXPORT/pkgs-foreign.txt"
    printf '%s\n' "${ALWAYS_INCLUDE[@]}"
} | sort -u | grep -vxF -f <(excluded_packages) \
    >"$PROFILE/packages_desktop.x86_64.new"
mv "$PROFILE/packages_desktop.x86_64.new" "$PROFILE/packages_desktop.x86_64"
printf '  %s packages\n' "$(wc -l <"$PROFILE/packages_desktop.x86_64")"

# AirSkyOS packages new enough? (Japanese font fix is in airskyos-kde-settings 2026.09.24-10)
kde_pkg=$(ls -1 "$LOCALREPO"/airskyos-kde-settings-*.pkg.tar.* 2>/dev/null | grep -v '\.sig$' | tail -n1 || true)
if [[ -n $kde_pkg ]] && ! bsdtar -tf "$kde_pkg" 2>/dev/null | grep -q '64-airskyos-cjk.conf'; then
    warn "airskyos-kde-settings in the local repository is too old (Japanese text will look Mincho)."
    warn "  build airskyos-branding pkgrel 10 or later, then run 02 again"
fi

# --- local repository (build time only; not copied into the ISO) ----------
msg "Adding the local repository to the build pacman.conf"
awk -v name="$LOCALREPO_NAME" -v path="$LOCALREPO" '
    !done && /^\[/ && $0 != "[options]" {
        print "[" name "]"
        print "SigLevel = Optional TrustAll"
        print "Server = file://" path
        print ""
        done = 1
    }
    { print }' "$PROFILE/pacman.conf" >"$PROFILE/pacman.conf.new"
mv "$PROFILE/pacman.conf.new" "$PROFILE/pacman.conf"

# --- names -----------------------------------------------------------------
msg "Branding the ISO"
if [[ -f $EXPORT/os-release.airskyos ]]; then
    cp "$EXPORT/os-release.airskyos" "$AIROOT/etc/os-release"
fi
sed -i \
    -e "s|^iso_label=.*|iso_label=\"${ISO_LABEL_PREFIX}_\$(date --date=\"@\${SOURCE_DATE_EPOCH:-\$(date +%s)}\" +%Y%m)\"|" \
    -e "s|^iso_publisher=.*|iso_publisher=\"$ISO_PUBLISHER\"|" \
    -e "s|^iso_application=.*|iso_application=\"$ISO_APPLICATION\"|" \
    "$PROFILE/profiledef.sh"
# boot menu titles (paths use lower-case "cachyos" and are left alone)
find "$PROFILE/grub" "$PROFILE/syslinux" "$PROFILE/efiboot" -type f \( -name '*.cfg' -o -name '*.conf' \) \
    -exec sed -i "s/CachyOS/$DISTRO_NAME/g" {} + 2>/dev/null || true
# output file name  (cachyos-desktop-linux-YYMMDD.iso -> airskyos-...)
sed -i 's/vars+=("cachyos")/vars+=("airskyos")/' "$ISOSRC/util-iso.sh"
sed -i "s/Installation Environment for .*CachyOS.*/Installation Environment for $DISTRO_NAME (based on CachyOS)./" "$ISOSRC/util-iso.sh"

# --- installer: copy the live system instead of downloading packages ------
msg "Installer: offline mode (installs exactly what is on the ISO)"
launcher="$AIROOT/usr/local/bin/calamares-online.sh"
sed -i \
    -e 's/local mode="online".*/local mode="offline"/' \
    -e 's/^\([[:space:]]*\)sudo pacman -Sy --noconfirm cachyos-calamares-next/\1# offline ISO: installer is preinstalled\n\1# &/' \
    -e 's|^\([[:space:]]*\)sudo cp "/usr/share/calamares/settings_${mode}.conf" /etc/calamares/settings.conf|&\n\1sudo sed -i "s/^branding:.*/branding: airskyos/" /etc/calamares/settings.conf|' \
    "$launcher"
grep -q 'mode="offline"' "$launcher" || warn "could not switch the installer to offline mode - check $launcher"
grep -q 'branding: airskyos' "$launcher" || warn "could not set the installer branding - check $launcher"

# --- live session: "Install AirSkyOS" launcher -----------------------------
msg "Live session: AirSkyOS installer launcher"
install -Dm755 "$KIT_DIR/live/airskyos-install"         "$AIROOT/usr/local/bin/airskyos-install"
install -Dm755 "$KIT_DIR/live/airskyos-live-session"    "$AIROOT/usr/local/bin/airskyos-live-session"
install -Dm755 "$KIT_DIR/live/airskyos-installer-setup" "$AIROOT/usr/local/bin/airskyos-installer-setup"
install -Dm755 "$KIT_DIR/live/airskyos-target-setup"    "$AIROOT/usr/local/bin/airskyos-target-setup"
# the AirSkyOS welcome app (1.3.x) looks for "airskyos-installer" before
# falling back to a bare "calamares"; point that name at our launcher too
ln -sf airskyos-install "$AIROOT/usr/local/bin/airskyos-installer"
install -Dm644 "$KIT_DIR/live/airskyos-install.desktop" "$AIROOT/usr/share/applications/airskyos-install.desktop"
install -Dm644 "$KIT_DIR/live/airskyos-live-session.desktop" "$AIROOT/etc/xdg/autostart/airskyos-live-session.desktop"
# keep the executable bits in the image
sed -i 's|^file_permissions=(|file_permissions=(\n  ["/usr/local/bin/airskyos-install"]="0:0:755"\n  ["/usr/local/bin/airskyos-live-session"]="0:0:755"\n  ["/usr/local/bin/airskyos-installer-setup"]="0:0:755"\n  ["/usr/local/bin/airskyos-target-setup"]="0:0:755"|' "$PROFILE/profiledef.sh"

# --- what the installer removes from the new system ------------------------
# CachyOS's list uses "pacman -Rsnc" (cascade): removing cmake would also
# remove airskyos-kwin-glass (it rebuilds itself with cmake) and the
# airskyos-branding meta package. Keep the build tools, drop the other boot
# loaders (AirSkyOS uses Limine only) and the live-only launcher files.
# The installer itself (Calamares) must stay until the end: the steps after
# "removeun" still run /etc/calamares/scripts/dmcheck etc. It is removed by
# airskyos-finish, the last step (added by airskyos-installer-setup).
# Packages you installed yourself (pkgs-repo/pkgs-foreign) are never removed.
removeun="$AIROOT/usr/local/bin/removeun"
cachy_rm=()
if [[ -f $removeun ]]; then
    mapfile -t cachy_rm < <(sed -n '/_packages_to_remove=(/,/^)/p' "$removeun" |
        sed '1d;$d; s/#.*//; s/[[:space:]]//g' | grep -v '^$' || true)
fi
((${#cachy_rm[@]})) || warn "could not read CachyOS's removal list - using the built-in one"
cachy_rm+=(gparted grsync edk2-shell boost-libs doxygen expect gpart tcpdump arch-install-scripts
           squashfs-tools elinks yaml-cpp syslinux clonezilla memtest86+ mkinitcpio-archiso refind grub)
user_pkgs=$(clean "$EXPORT/pkgs-repo.txt" "$EXPORT/pkgs-foreign.txt")
early=() late=(cachyos-calamares-next cachyos-calamares cachyos-calamares-config
               cachyos-calamares-grub cachyos-calamares-systemd cachyos-calamares-refind)
for p in $(printf '%s\n' "${cachy_rm[@]}" | awk '!seen[$0]++'); do
    case $p in cmake|extra-cmake-modules|cachyos-calamares*) continue ;; esac
    grep -qxF -- "$p" <<<"$user_pkgs" && { printf '  kept on install (you use it): %s\n' "$p"; continue; }
    early+=("$p")
done
late+=("${early[@]}")      # retried once the installer is gone (boost-libs, yaml-cpp, ...)
awk -v list="$(printf '  %s\n' "${early[@]}")" '$0=="# @AIRSKYOS_PACKAGES@"{print list; next} {print}' \
    "$KIT_DIR/live/airskyos-removeun" >"$removeun"
awk -v list="_late=($(printf ' %s' "${late[@]}") )" '$0=="# @AIRSKYOS_LATE_PACKAGES@"{print list; next} {print}' \
    "$KIT_DIR/live/airskyos-finish" >"$AIROOT/usr/local/bin/airskyos-finish"
chmod 755 "$removeun" "$AIROOT/usr/local/bin/airskyos-finish"
grep -q '^  boost-libs$\|^  gparted$' "$removeun" || grep -q '^  mkinitcpio-archiso$' "$removeun" || warn "removal list looks empty"
grep -q 'calamares' <(sed -n '/_packages_to_remove=(/,/^)/p' "$removeun") && die "installer would be removed too early"
grep -q '^_late=( cachyos-calamares-next' "$AIROOT/usr/local/bin/airskyos-finish" || die "airskyos-finish was not generated"
grep -q '"/usr/local/bin/removeun"' "$PROFILE/profiledef.sh" || \
    sed -i 's|^file_permissions=(|file_permissions=(\n  ["/usr/local/bin/removeun"]="0:0:755"|' "$PROFILE/profiledef.sh"
sed -i 's|^file_permissions=(|file_permissions=(\n  ["/usr/local/bin/airskyos-finish"]="0:0:755"|' "$PROFILE/profiledef.sh"

# --- ISO-build-only pacman hooks ------------------------------------------
# Files containing "remove from airootfs" are deleted at the end of the build
# by CachyOS's zzzz99 hook, so none of this reaches installed systems.
msg "Build hooks: initramfs without an EFI partition, AirSkyOS Limine in the installer"
mkdir -p "$AIROOT/etc/pacman.d/hooks"
cp "$KIT_DIR"/iso-hooks/* "$AIROOT/etc/pacman.d/hooks/"
chmod 755 "$AIROOT/etc/pacman.d/hooks/"*.sh 2>/dev/null || true

# --- installer branding ----------------------------------------------------
msg "Installer branding (Calamares)"
tmp=$(mktemp -d)
git clone -q --depth 1 --filter=blob:none --sparse -b "$CACHYOS_CALAMARES_BRANCH" "$CACHYOS_CALAMARES_GIT" "$tmp/cal"
git -C "$tmp/cal" sparse-checkout set src/branding/cachyos
B="$AIROOT/usr/share/calamares/branding/airskyos"
mkdir -p "$B"
cp -r "$tmp/cal/src/branding/cachyos/." "$B/"
rm -rf "$tmp" "$B"/slide*.jxl
sed -i \
    -e 's/^componentName:.*/componentName:  airskyos/' \
    -e "s/^\(\s*\)\(productName\|shortProductName\|versionedName\|shortVersionedName\|bootloaderEntryName\):.*/\1\2: $DISTRO_NAME/" \
    -e "s/^\(\s*\)\(version\|shortVersion\):.*/\1\2: $(date +%Y.%m.%d)/" \
    -e 's/SidebarBackground:.*/SidebarBackground:        "#13325E"/' \
    -e 's/SidebarBackgroundCurrent:.*/SidebarBackgroundCurrent: "#5DADEC"/' \
    -e 's/SidebarTextCurrent:.*/SidebarTextCurrent:       "#13325E"/' \
    "$B/branding.desc"
# never upload install logs to CachyOS's paste server
sed -i '/^uploadServer/,$d' "$B/branding.desc"
# logo / icon / welcome picture
icon=/usr/share/airskyos/aozora1.png
if [[ -f $icon ]]; then
    if command -v magick >/dev/null 2>&1; then
        magick "$icon" -resize 128x128 "$B/logo.png"
        magick "$icon" -resize 64x64 "$B/icon.png"
    else
        cp "$icon" "$B/logo.png"; cp "$icon" "$B/icon.png"
    fi
fi
if [[ -f /usr/share/pixmaps/AirSky-logo.svg ]] && command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w 640 /usr/share/pixmaps/AirSky-logo.svg -o "$B/welcome.png"
elif [[ -f $icon ]]; then
    cp "$icon" "$B/welcome.png"
fi
cp "$KIT_DIR/calamares/show.qml" "$B/show.qml"

# --- services ----------------------------------------------------------------
msg "Enabling extra services"
while read -r unit; do
    [[ -n $unit ]] || continue
    src=/usr/lib/systemd/system/$unit
    [[ -f $src ]] || { warn "unit not found on this PC: $unit"; continue; }
    wanted=$(sed -n 's/^WantedBy=//p' "$src" | head -n1)
    [[ -n $wanted ]] || { warn "$unit has no WantedBy=, skipped"; continue; }
    for w in $wanted; do
        mkdir -p "$AIROOT/etc/systemd/system/$w.wants"
        ln -sf "$src" "$AIROOT/etc/systemd/system/$w.wants/$unit"
    done
    printf '  %s -> %s\n' "$unit" "$wanted"
done < <(clean "$KIT_DIR/extra-services.txt" || true)

# --- your own files ------------------------------------------------------------
if [[ -d $KIT_DIR/airootfs-overlay ]] && [[ -n $(ls -A "$KIT_DIR/airootfs-overlay") ]]; then
    msg "Copying airootfs-overlay/ into the ISO"
    cp -a "$KIT_DIR/airootfs-overlay/." "$AIROOT/"
    rm -f "$AIROOT/README.txt"
fi

# --- privacy check -------------------------------------------------------------
if find "$AIROOT/home" -mindepth 1 -maxdepth 1 2>/dev/null | grep -q .; then
    warn "airootfs/home is not empty - make sure no personal files end up on the ISO"
fi

msg "Profile ready: $PROFILE"
echo "  next: ./04-build-iso.sh"
