# qsgreeter

A QuickShell (QML) login greeter for greetd. Fork of `taleroangel/greetd-qsgreeter`; this fork
adds a Hyprland session config alongside the upstream niri one.

## Layout

- `qsgreeter/` — the QuickShell config, installed to `/etc/xdg/quickshell/qsgreeter`.
  `shell.qml` is the entry point. `Services/` talks to greetd, logind and the user/session lists;
  `Components/` is UI; `Theme/` reads `colorscheme.json` and `style.json`; `L10n/` holds the
  translations (`en.json`, `es.json`).
- `niri/`, `hyprland/` — compositor configs that launch the greeter, installed to `/etc/greetd/`.
- `Makefile` — `install` / `uninstall`, honours `DESTDIR` and `PREFIX`.
- `PKGBUILD` — Arch `-git` package that runs `make install`.
- `aur/PKGBUILD` — release package (`qsgreeter-hyprland`) built from a `v*` tag tarball.
  Its `pkgver` and `sha256sums` are placeholders that the release workflow fills in.
- `.github/workflows/ci.yml` — every push and PR: qmllint, `make install`/`uninstall` into a
  scratch root, and a build of `aur/PKGBUILD` from the commit.
- `.github/workflows/release.yml` — `v*` tags on main only: namcap, build from the tag,
  publish to the AUR with the `AUR_SSH_PRIVATE_KEY` secret.

## Checking a change

There is no build step. To check one:

- Install into a scratch root and inspect the result:
  `make install DESTDIR="$(mktemp -d)"`
- Lint the QML: `.github/scripts/qmllint.sh`. It builds the `qs.*` module tree Quickshell
  creates at runtime so those imports resolve, fails on syntax errors, and reports the rest
  as warnings. Some Quickshell types still will not resolve outside a session; act on real
  syntax and type errors. The duplicate `proc` id in `UserService.qml` is a known false
  positive (the second one is inside a delegate, its own scope).

## Review rules

When reviewing a PR, focus on:

1. **greetd protocol handling** (`Services/LoginService.qml`). Answer auth prompts by
   `responseRequired` / `echoResponse`, never by matching prompt text — PAM prompts vary
   between setups and locales. A failed or cancelled auth must return the UI to a usable state.
2. **Never lock the user out.** Any path that can leave the greeter with no input focus, no
   visible field or a hung session start is a blocking bug.
3. **Secrets.** Passwords must not be logged, echoed, stored in properties that outlive the
   attempt, or passed on a command line.
4. **Install paths.** Every new file under `qsgreeter/` is picked up by the Makefile's `find`,
   but new top-level config (like a compositor config) needs its own `install` *and*
   `uninstall` lines, and must respect `DESTDIR`.
5. **PKGBUILD.** `depends`/`optdepends` match what the code actually calls; `pkgver()` stays
   intact; `url` points at the repo the package is meant to build from.
6. **L10n.** User-visible strings go through `L10n`, and every key added to `en.json` also
   exists in `es.json`.
7. **Theming.** Colours and sizes come from `Theme/`, not hardcoded values in components.

Do not comment on formatting or style alone.

## Making changes

- Keep changes small and in the style of the surrounding QML (4-space indent, `id` first,
  properties before signal handlers before children).
- Commit messages: imperative summary line, body explaining why.
- Do not bump `pkgver` by hand; `pkgver()` computes it.
