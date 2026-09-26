#!/usr/bin/env bash
# Copy the greeter to <dest>/qs and give each directory the qmldir Quickshell
# generates at runtime, so `import qs.<Dir>` resolves outside Quickshell.
# Put <dest> on the QML import path.
#
#   qs-modules.sh <source dir> <dest>
set -euo pipefail

src=$1 dest=$2
mkdir -p "$dest"
cp -r "$src" "$dest/qs"

for dir in "$dest"/qs/*/; do
    compgen -G "$dir*.qml" >/dev/null || continue
    name=$(basename "$dir")
    {
        echo "module qs.$name"
        for f in "$dir"*.qml; do
            base=$(basename "$f")
            if grep -q '^pragma Singleton' "$f"; then
                echo "singleton ${base%.qml} 1.0 $base"
            else
                echo "${base%.qml} 1.0 $base"
            fi
        done
    } > "$dir/qmldir"
done
