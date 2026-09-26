#!/usr/bin/env bash
# Build aur/PKGBUILD as an unprivileged user, the way the AUR will see it.
#
#   build-package.sh <pkgver> local   package this checkout (CI on every push)
#   build-package.sh <pkgver> tag     package the published v<pkgver> tarball (release)
#
# Leaves PKGBUILD, .SRCINFO and the package in ./aur-build. Run as root in an
# Arch container: makepkg itself runs as the `builder` user.
set -euo pipefail

pkgver=$1 mode=$2
out=$PWD/aur-build
mkdir "$out"

sed -e "s/^pkgver=.*/pkgver=$pkgver/" -e "s/^pkgrel=.*/pkgrel=1/" aur/PKGBUILD > "$out/PKGBUILD"
pkgname=$(sed -n 's/^pkgname=//p' "$out/PKGBUILD")

case $mode in
    local)
        # Stand in for the GitHub tag tarball, with the same top-level directory.
        git archive --prefix="greetd-qsgreeter-$pkgver/" \
            -o "$out/$pkgname-$pkgver.tar.gz" HEAD ;;
    tag) ;;
    *) echo "::error::unknown mode '$mode'"; exit 1 ;;
esac

id -u builder >/dev/null 2>&1 || useradd -m builder
chown -R builder: "$out"
cd "$out"
runuser -u builder -- updpkgsums
runuser -u builder -- makepkg --cleanbuild --noconfirm
runuser -u builder -- makepkg --printsrcinfo > .SRCINFO
