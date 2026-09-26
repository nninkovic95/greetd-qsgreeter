# qsgreeter

A [QuickShell](https://quickshell.org/)-based greeter for [greetd](https://sr.ht/~kennylevinsen/greetd/). It provides a simple QML-based login interface for Wayland.

| User List | Login Screen |
| :---: | :---: |
| ![Users](docs/screenshot_users.png) | ![Login](docs/screenshot_login.png) |

<video src="https://github.com/nninkovic95/greetd-qsgreeter/raw/main/docs/video.mp4" controls width="100%"></video>

[Demo video](docs/video.mp4) (H.264/AAC MP4, 14 s)

## 📋 Requirements

- [greetd](https://sr.ht/~kennylevinsen/greetd/)
- [QuickShell](https://quickshell.org/), which needs Qt 6.6 or later
- `gdbus` (from glib2) and [AccountsService](https://www.freedesktop.org/wiki/Software/AccountsService/): the user list, real names and avatars are read from `org.freedesktop.Accounts`
- A Wayland compositor to run the greeter in; a [Hyprland](https://hypr.land) configuration is provided
- systemd: the shutdown and reboot buttons run `systemctl poweroff` and `systemctl reboot` as the greeter user

Sessions are read from the `.desktop` files in the `wayland-sessions` directory of every `XDG_DATA_DIRS`
entry (`/usr/local/share` and `/usr/share` by default). Entries marked `Hidden` or `NoDisplay`, or whose
`TryExec` program is not installed, are skipped.

## 🪛 Installation
Use _make_ to copy the greeter into `/etc/xdg/quickshell/qsgreeter` and `qsgreeter-hyprland.lua` into
`/etc/greetd/`.

```sh
git clone https://github.com/nninkovic95/greetd-qsgreeter
cd greetd-qsgreeter
sudo make install
```

Uninstall the package with:
```sh
sudo make uninstall
```

### Arch Linux
Available in the AUR as [qsgreeter-hyprland-git](https://aur.archlinux.org/packages/qsgreeter-hyprland-git).
It builds from this repository and pulls in `greetd`, `quickshell`, `hyprland`, `glib2` and `accountsservice`.

```sh
paru -S qsgreeter-hyprland-git   # or: yay -S qsgreeter-hyprland-git
```

The package installs the greeter into `/etc/xdg/quickshell/qsgreeter` and the Hyprland config into
`/etc/greetd/qsgreeter-hyprland.lua`. It does not edit `/etc/greetd/config.toml`; see
[Using with Hyprland](#using-with-hyprland) for the two lines to add.

Without an AUR helper:

```sh
git clone https://aur.archlinux.org/qsgreeter-hyprland-git.git
cd qsgreeter-hyprland-git
makepkg -si
```

Without a package, clone this repository and run `sudo make install` as shown above.

## 🚀 Launch

To use **qsgreeter**, run the following command from your chosen Wayland compositor:

```sh
quickshell -c qsgreeter
```

i.e, running from Hyprland `hl.exec_cmd("quickshell -c qsgreeter")`

### Using with Hyprland
If you have [Hyprland](https://hypr.land) installed, you can use the provided [Hyprland configuration file](hyprland/qsgreeter-hyprland.lua) to start the greeter automatically. Place the configuration file at `/etc/greetd/qsgreeter-hyprland.lua` (`make install` and the AUR package do this) and edit `/etc/greetd/config.toml` to launch Hyprland with the specified configuration:

```toml
[terminal]
vt = 1

[default_session]
command = "start-hyprland -- --config /etc/greetd/qsgreeter-hyprland.lua"
user = "greeter"
```

The configuration uses Hyprland's Lua config format, selected by the `.lua` extension. It starts
the greeter, maximizes its window, and exits Hyprland once the greeter quits so greetd can launch
the selected session. `start-hyprland` is Hyprland's watchdog launcher; running the `Hyprland`
binary directly works too but shows a warning banner on the greeter screen.

## 🎨 Customization

Configuration files are located at `/etc/xdg/quickshell/qsgreeter`. You can customize the look and feel by editing `colorscheme.json` and `style.json`. Both files are watched, so edits apply while the greeter is running. In `style.json`, `scale` multiplies every size (fonts, margins, buttons and avatars) at once.

Since the greeter is written entirely in **QML**, you can also rearrange elements as you wish.

### Language

The greeter follows the locale of its own process (`LANG`), which is normally the system locale. Translations live in `qsgreeter/L10n/` (`en.json`, `es.json`); any other language, and any key a translation lacks, falls back to English.

## 🤖 AI Disclosure
Code was written entirely by me, but AI was used for technical guidance
