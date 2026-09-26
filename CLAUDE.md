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

## Checking a change

There is no build step. To check one:

- Install into a scratch root and inspect the result:
  `make install DESTDIR="$(mktemp -d)"`
- Lint edited QML: `qmllint <file>.qml`. Imports from `Quickshell` and
  `Quickshell.Services.Greetd` will not resolve in CI; ignore those warnings, act on real
  syntax and type errors.

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
