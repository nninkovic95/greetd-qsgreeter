#!/usr/bin/env bash
# Lint the greeter's QML with qmllint.
#
# Quickshell resolves `import qs.<Dir>` at runtime by turning each top-level
# directory into a module; qmllint cannot, so this rebuilds that module tree
# first. Syntax errors fail the run. Every other finding is reported as an
# annotation and counted in the job summary, since some Quickshell types do
# not resolve outside a running session.
#
#   qmllint.sh [source dir]    (default: qsgreeter)
set -euo pipefail

src=${1:-qsgreeter}
qmllint=${QMLLINT:-/usr/lib/qt6/bin/qmllint}
summary=${GITHUB_STEP_SUMMARY:-/dev/null}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# qs.<Dir> modules: one qmldir per directory, singletons marked as such.
mkdir -p "$work/imports/qs"
for dir in "$src"/*/; do
    compgen -G "$dir*.qml" >/dev/null || continue
    name=$(basename "$dir")
    mod="$work/imports/qs/$name"
    mkdir -p "$mod"
    echo "module qs.$name" > "$mod/qmldir"
    for f in "$dir"*.qml "$dir"*.js; do
        [ -e "$f" ] || continue
        base=$(basename "$f")
        ln -s "$(realpath "$f")" "$mod/$base"
        case $base in
            *.js) ;;
            *) if grep -q '^pragma Singleton' "$f"; then
                   echo "singleton ${base%.qml} 1.0 $base" >> "$mod/qmldir"
               else
                   echo "${base%.qml} 1.0 $base" >> "$mod/qmldir"
               fi ;;
        esac
    done
done

mapfile -d '' files < <(find "$src" -name '*.qml' -print0 | sort -z)
[ ${#files[@]} -gt 0 ] || { echo "::error::no QML files under $src"; exit 1; }

# qmllint exits non-zero on any warning; the JSON report decides instead.
"$qmllint" -I "$work/imports" --json "$work/report.json" "${files[@]}" >/dev/null 2>&1 || true
linted=$(jq '.files | length' "$work/report.json" 2>/dev/null || echo 0)
if [ "$linted" -ne ${#files[@]} ]; then
    echo "::error::qmllint reported on $linted of ${#files[@]} files"
    exit 1
fi

# One annotation per finding: syntax errors as errors, the rest as warnings.
jq -r --arg pwd "$PWD/" '
    def esc: gsub("%"; "%25") | gsub("\r"; "%0D") | gsub("\n"; "%0A");
    .files[] | (.filename | ltrimstr($pwd)) as $f | .warnings[] |
    "::\(if .id == "syntax" then "error" else "warning" end) file=\($f),line=\(.line // 1),col=\(.column // 1),title=qmllint [\(.id)]::\(.message | esc)"
' "$work/report.json"

{
    echo "### qmllint"
    echo
    echo "${#files[@]} files linted."
    echo
    echo "| Category | Findings |"
    echo "| --- | --- |"
    jq -r '[.files[].warnings[].id] | group_by(.) | map([.[0], length]) | sort_by(-.[1])[] | "| \(.[0]) | \(.[1]) |"' "$work/report.json"
} >> "$summary"

syntax=$(jq '[.files[].warnings[] | select(.id == "syntax")] | length' "$work/report.json")
if [ "$syntax" -gt 0 ]; then
    echo "::error::qmllint found $syntax syntax error(s)"
    exit 1
fi
