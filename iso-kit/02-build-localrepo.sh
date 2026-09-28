#!/usr/bin/env bash
# 2. Put every foreign package (AUR + AirSkyOS builds) into a local pacman
#    repository that the ISO build can install from.
#
#    Usage: ./02-build-localrepo.sh [extra dirs with *.pkg.tar.zst ...]
#
#    Package files are found in: the local repository folder itself
#    (you can copy .pkg.tar.zst files straight into it), the pacman / paru /
#    yay caches, PKG_SEARCH_DIRS in config.sh, and any folder given as an
#    argument (searched recursively).
#
#    Files are identified by the name inside the package (.PKGINFO), not by
#    the file name. If the exact installed version is not available, the
#    newest file of that package is used and a note is printed.
set -euo pipefail
. "$(dirname "$0")/config.sh"
trap 'die "stopped at line $LINENO: $BASH_COMMAND"' ERR

[[ -f $EXPORT/pkgs-foreign-versions.txt ]] || die "run 01-export-system.sh first"
command -v repo-add >/dev/null || die "repo-add not found (pacman package)"
command -v bsdtar >/dev/null || die "bsdtar not found (pacman -S libarchive)"

mkdir -p "$LOCALREPO"
dirs=("$LOCALREPO" "${PKG_SEARCH_DIRS[@]}" "$@")

# --- index the package files we need: name <TAB> version <TAB> path --------
# Only files whose name starts like a wanted package are opened, so a big
# pacman cache is scanned quickly. Unreadable folders (e.g. pacman's
# download-* dirs) are skipped.
msg "Scanning for package files"
index=$(mktemp)
wanted=$(mktemp)
trap 'rm -f "$index" "$wanted"' EXIT
awk '{print $1}' "$EXPORT/pkgs-foreign-versions.txt" | sort -u >"$wanted"

candidates() {
    local d
    for d in "${dirs[@]}"; do
        if [[ ! -d $d ]]; then
            [[ $d == "$LOCALREPO" ]] || warn "folder not found: $d"
            continue
        fi
        find -L "$d" -maxdepth 6 -type f \( -name '*.pkg.tar.zst' -o -name '*.pkg.tar.xz' \) 2>/dev/null || true
    done
}

while read -r f; do
    base=${f##*/}
    guess=${base%-*-*-*}                   # strip -pkgver-pkgrel-arch.pkg.tar.*
    grep -qxF -- "$guess" "$wanted" || continue
    info=$(bsdtar -xOf "$f" .PKGINFO 2>/dev/null) || continue
    name=$(sed -n 's/^pkgname = //p' <<<"$info")
    ver=$(sed -n 's/^pkgver = //p' <<<"$info")
    if [[ -n $name && -n $ver ]]; then
        printf '%s\t%s\t%s\n' "$name" "$ver" "$f" >>"$index"
    fi
done < <(candidates | sort -u)
printf '  %s matching package files found\n' "$(wc -l <"$index")"

excluded() { excluded_packages | grep -qxF -- "$1"; }

newest() {   # newest version among "ver<TAB>path" lines on stdin
    local best_v="" best_p="" v p
    while IFS=$'\t' read -r v p; do
        if [[ -z $best_v ]] || (($(vercmp "$v" "$best_v") > 0)); then
            best_v=$v; best_p=$p
        fi
    done
    [[ -n $best_p ]] && printf '%s\t%s\n' "$best_v" "$best_p"
}

missing=()
while read -r name ver; do
    [[ -n $name ]] || continue
    if excluded "$name"; then
        printf '  %-45s %s\n' "$name $ver" "excluded"
        continue
    fi
    exact=$(awk -F'\t' -v n="$name" -v v="$ver" '$1==n && $2==v {print $3; exit}' "$index")
    if [[ -n $exact ]]; then
        file=$exact; note="OK"
    else
        pick=$(awk -F'\t' -v n="$name" '$1==n {print $2 "\t" $3}' "$index" | newest || true)
        if [[ -z $pick ]]; then
            missing+=("$name $ver")
            printf '  %-45s %s\n' "$name $ver" "NOT FOUND"
            continue
        fi
        file=${pick#*$'\t'}; note="OK (using ${pick%%$'\t'*}, installed: $ver)"
    fi
    # copy into the repository folder unless it already lives there
    if [[ $(dirname "$(realpath "$file")") != "$(realpath "$LOCALREPO")" ]]; then
        cp -f "$file" "$LOCALREPO/"
        [[ -f $file.sig ]] && cp -f "$file.sig" "$LOCALREPO/"
    fi
    printf '  %-45s %s\n' "$name $ver" "$note"
done <"$EXPORT/pkgs-foreign-versions.txt"

# --- keep only the newest file per package, then (re)build the database ----
shopt -s nullglob
declare -A keep=()
for f in "$LOCALREPO"/*.pkg.tar.zst "$LOCALREPO"/*.pkg.tar.xz; do
    info=$(bsdtar -xOf "$f" .PKGINFO 2>/dev/null) || continue
    n=$(sed -n 's/^pkgname = //p' <<<"$info"); v=$(sed -n 's/^pkgver = //p' <<<"$info")
    [[ -n $n && -n $v ]] || continue
    if [[ -z ${keep[$n]:-} ]] || (($(vercmp "$v" "${keep[$n]%%|*}") > 0)); then
        keep[$n]="$v|$f"
    fi
done
pkgfiles=()
for n in "${!keep[@]}"; do pkgfiles+=("${keep[$n]#*|}"); done
((${#pkgfiles[@]})) || die "no packages collected"

rm -f "$LOCALREPO/$LOCALREPO_NAME".{db,files}*
repo-add -q "$LOCALREPO/$LOCALREPO_NAME.db.tar.gz" "${pkgfiles[@]}"
chmod -R a+rX "$LOCALREPO"     # mkarchiso runs as root and reads it via file://
printf '  %s packages in %s\n' "${#pkgfiles[@]}" "$LOCALREPO"

if ((${#missing[@]})); then
    warn "no package file for:"
    printf '     %s\n' "${missing[@]}"
    cat <<HINT
  Build them and run this script again, e.g.
     AUR:      paru -G <name> && cd <name> && makepkg -s
     AirSkyOS: cd <repository>/packages/<dir> && makepkg -sf
  or copy the .pkg.tar.zst into $LOCALREPO, or pass its folder as an argument.
  Packages you do not want on the ISO can go into exclude-packages.txt.
HINT
    exit 1
fi
msg "local repository ready: $LOCALREPO ($LOCALREPO_NAME)"
