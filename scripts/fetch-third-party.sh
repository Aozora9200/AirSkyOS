#!/usr/bin/env bash
# Download the third-party desktop widgets that AirSkyOS uses unmodified,
# at the exact versions AirSkyOS was built with, into theme/plasmoids/.
# They are not stored in this repository; see NOTICE.md for their licenses.
set -euo pipefail
cd "$(dirname "$0")/.."
dest=theme/plasmoids
mkdir -p "$dest"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# name  git-url  tag  folder-in-repo  installed-as
widgets=(
  "Material-Clock|https://github.com/cesp99/Material-Clock|V0.0.4|package|material.clock"
  "Panel-Colorizer|https://github.com/luisbocanegra/plasma-panel-colorizer|v7.0.1|package|luisbocanegra.panel.colorizer"
)

for w in "${widgets[@]}"; do
    IFS='|' read -r name url tag sub id <<<"$w"
    echo "==> $name $tag"
    git -c advice.detachedHead=false clone -q --depth 1 --branch "$tag" "$url" "$tmp/$name"
    rm -rf "${dest:?}/$id"
    cp -r "$tmp/$name/$sub" "$dest/$id"
    install -Dm644 "$tmp/$name/LICENSE" "$dest/$id/LICENSE"
done
echo "==> done: $dest"
