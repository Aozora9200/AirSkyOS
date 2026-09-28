#!/usr/bin/env bash
# 6. List where the source code of every package on the ISO can be found.
#
#    The ISO contains GPL software in binary form. Whoever distributes the
#    ISO must also make the matching source code available. This script
#    writes a table (package, version, repository, source) that you can
#    publish next to the ISO, e.g. as a GitHub release asset.
#
#    Usage: ./06-source-manifest.sh [path/to/airskyos-*.pkgs.txt]
#           (default: the newest *.pkgs.txt in $WORK/iso-out or the build dir)
#    Output: <same name>.sources.tsv  and  .sources.md
set -euo pipefail
. "$(dirname "$0")/config.sh"

list=${1:-}
if [[ -z $list ]]; then
    list=$(ls -t "$WORK"/iso-out/*.pkgs.txt "$ISOSRC"/out/*.pkgs.txt 2>/dev/null | head -n1 || true)
fi
[[ -n $list && -f $list ]] || die "package list not found - pass the *.pkgs.txt that 04 produced"
command -v bsdtar >/dev/null || die "bsdtar not found (pacman -S libarchive)"

out=${list%.pkgs.txt}
msg "Reading package databases"
# name <TAB> base <TAB> repo, from the sync databases and the local repository
db_index=$(mktemp); trap 'rm -f "$db_index"' EXIT
index_db() {   # index_db <db file> <repo name>
    bsdtar -xOf "$1" '*/desc' 2>/dev/null | awk -v repo="$2" '
        /^%NAME%$/ { getline; n = $0 }
        /^%BASE%$/ { getline; b = $0 }
        /^%BUILDDATE%$/ { if (n != "") print n "\t" (b != "" ? b : n) "\t" repo; n = b = "" }
    '
}
index_db "$LOCALREPO/$LOCALREPO_NAME.db" "$LOCALREPO_NAME" >>"$db_index" 2>/dev/null || true
for db in /var/lib/pacman/sync/*.db; do
    index_db "$db" "$(basename "$db" .db)" >>"$db_index"
done

source_of() {   # source_of <repo> <base>
    local repo=$1 base=$2
    case $base in
        linux-cachyos*) echo "https://github.com/CachyOS/linux-cachyos (folder $base)"; return ;;
    esac
    case $repo in
        "$LOCALREPO_NAME")
            case $base in
                airskyos-*) echo "this repository: packages/$base (AirSkyOS)" ;;
                cachyos-calamares*) echo "https://github.com/CachyOS/CachyOS-PKGBUILDS/tree/master/cachyos-calamares (rebuilt unchanged by 02b)" ;;
                *) echo "https://aur.archlinux.org/packages/$base (AUR, or your own PKGBUILD)" ;;
            esac ;;
        core|extra|multilib|core-testing|extra-testing)
            echo "https://gitlab.archlinux.org/archlinux/packaging/packages/$base" ;;
        cachyos)
            echo "https://github.com/CachyOS/CachyOS-PKGBUILDS (folder $base)" ;;
        cachyos-*)
            # CachyOS's optimised rebuilds of Arch packages (v3/v4/znver4);
            # packages CachyOS maintains itself are in CachyOS-PKGBUILDS
            echo "https://gitlab.archlinux.org/archlinux/packaging/packages/$base (rebuilt by CachyOS; CachyOS's own: https://github.com/CachyOS/CachyOS-PKGBUILDS)" ;;
        *) echo "repository $repo: $base" ;;
    esac
}

msg "Writing $out.sources.tsv / .md"
{
    printf 'package\tversion\trepository\tpkgbase\tsource\n'
    while read -r name ver _; do
        [[ -n $name && $name != \#* ]] || continue
        hit=$(awk -F'\t' -v n="$name" '$1 == n { print; exit }' "$db_index")
        if [[ -n $hit ]]; then
            IFS=$'\t' read -r _ base repo <<<"$hit"
        else
            base=$name; repo=unknown
        fi
        printf '%s\t%s\t%s\t%s\t%s\n' "$name" "${ver:-?}" "$repo" "$base" "$(source_of "$repo" "$base")"
    done <"$list"
} >"$out.sources.tsv"

{
    echo "# Source code for $(basename "$out").iso"
    echo
    echo "Every package on this ISO and where its source code (PKGBUILD and upstream sources) can be found."
    echo "Arch Linux also keeps source tarballs at <https://sources.archlinux.org/>."
    echo
    echo "| package | version | repository | source |"
    echo "|---|---|---|---|"
    tail -n +2 "$out.sources.tsv" | awk -F'\t' '{ printf "| %s | %s | %s | %s |\n", $1, $2, $3, $5 }'
} >"$out.sources.md"

unknown=$(awk -F'\t' 'NR > 1 && $3 == "unknown"' "$out.sources.tsv" | wc -l)
printf '  %s packages\n' "$(($(wc -l <"$out.sources.tsv") - 1))"
((unknown == 0)) || warn "$unknown packages were not found in any database (see 'unknown' in the table)"
msg "done: $out.sources.md"
