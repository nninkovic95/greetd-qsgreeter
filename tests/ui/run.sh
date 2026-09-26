#!/usr/bin/env bash
# Run the real greeter against stub Quickshell and greetd modules and drive
# it through user selection and login (tst_greeter.qml). Screenshots of each
# screen go to the output directory. Exits non-zero if the greeter does not
# reach a usable state.
#
#   tests/ui/run.sh [output dir]    (default: ./ui-screenshots)
#
# Without a DISPLAY it starts Xvfb, and Mesa renders in software. Set
# QT_QPA_PLATFORM=offscreen to run without X at all.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
out=$(mkdir -p "${1:-ui-screenshots}" && cd "${1:-ui-screenshots}" && pwd)
bin=${QT_BIN:-/usr/lib/qt6/bin}
work=$(mktemp -d)
xvfb_pid=
cleanup() {
    [ -n "$xvfb_pid" ] && kill "$xvfb_pid" 2>/dev/null || true
    rm -rf "$work"
}
trap cleanup EXIT

# The greeter as Quickshell would see it, plus the harness beside it.
"$repo/.github/scripts/qs-modules.sh" "$repo/qsgreeter" "$work/imports"
cp -r "$here/stubs" "$here/fixtures" "$here/tst_greeter.qml" "$work/"
cat > "$work/stubs/Quickshell/Io/env.js" <<EOF
.pragma library
var shellDir = "$work/imports/qs";
var fixturesDir = "$work/fixtures";
var screenshotsDir = "$out";
EOF

if [ -z "${DISPLAY:-}" ] && [ "${QT_QPA_PLATFORM:-}" != offscreen ]; then
    Xvfb :99 -screen 0 1280x800x24 -nolisten tcp >/dev/null 2>&1 &
    xvfb_pid=$!
    export DISPLAY=:99
    for _ in $(seq 50); do
        [ -S /tmp/.X11-unix/X99 ] && break
        sleep 0.1
    done
    [ -S /tmp/.X11-unix/X99 ] || { echo "::error::Xvfb did not start"; exit 1; }
fi

export QML_XHR_ALLOW_FILE_READ=1        # FileView stub reads through XHR
export QT_QUICK_CONTROLS_STYLE=Basic
export LIBGL_ALWAYS_SOFTWARE=1          # Mesa llvmpipe
export QSG_INFO=1                       # log which renderer was used
export LANG=C.UTF-8                     # the greeter falls back to en.json

status=0
"$bin/qmltestrunner" -input "$work/tst_greeter.qml" \
    -import "$work/stubs" -import "$work/imports" 2>&1 | tee "$work/log.txt" || status=$?

# Known problems the test reports but does not fail on, and QML runtime
# warnings from the greeter, as annotations.
sed -n 's/.*HARNESS-WARNING: //p' "$work/log.txt" | sort -u | while read -r line; do
    echo "::warning title=Greeter UI::$line"
done
# (`|| true`: finding no warnings is fine, and must not trip pipefail.)
{ grep -E '^QWARN .*(file://|qrc:).*(Error|error|Cannot|Unable|undefined|not a function|Binding loop)' "$work/log.txt" \
    | grep -v HARNESS-WARNING || true; } | sed -E 's/^QWARN *: *[^ ]+ //' | sort -u | while read -r line; do
        echo "::warning title=QML runtime warning::${line//file:\/\/$work\/imports\//}"
    done

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo "### Greeter UI"
        echo
        { grep -E '^(PASS|FAIL|SKIP)' "$work/log.txt" || true; } | sed 's/^/- /'
        echo
        echo "Screenshots: $(ls "$out" | tr '\n' ' ')"
    } >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$status" -ne 0 ]; then
    echo "::error title=Greeter UI::the greeter did not reach a usable state (see the FAIL lines above)"
    exit 1
fi
