# qsgreeter

A [QuickShell](https://quickshell.org/)-based greeter for [greetd](https://sr.ht/~kennylevinsen/greetd/). It provides a simple QML-based login interface for Wayland.

| User List | Login Screen |
| :---: | :---: |
| ![Users](docs/screenshot_users.png) | ![Login](docs/screenshot_login.png) |

<video src="https://github.com/user-attachments/assets/b735015b-3ff1-487f-8bdd-55576835c9d0" controls width="100%"></video>

## 🪛 Installation
Use _make_ to copy files into standard _quickshell_ directories. If _Hyprland_ is present, the script
will also install `qsgreeter-hyprland.lua` into `/etc/greetd/`

```sh
git clone https://github.com/taleroangel/greetd-qsgreeter
cd greetd-qsgreeter
sudo make install
```

Uninstall the package with:
```sh
sudo make uninstall
```

### Arch Linux
Available in the AUR as [qsgreeter-hyprland-git](https://aur.archlinux.org/packages/qsgreeter-hyprland-git).
It tracks this branch and pulls in `greetd`, `quickshell`, `hyprland`, `glib2` and `accountsservice`.

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

Manual install without a package:

```sh
git clone -b hyprland https://github.com/nninkovic95/greetd-qsgreeter
cd greetd-qsgreeter
sudo make install
```

## 🚀 Launch

To use **qsgreeter**, run the following command from your chosen Wayland compositor:

```sh
quickshell -c qsgreeter
```

i.e, running from Hyprland `hl.exec_cmd("quickshell -c qsgreeter")`

### Using with Hyprland
If you have [Hyprland](https://hypr.land) installed, you can use the provided [Hyprland configuration file](hyprland/qsgreeter-hyprland.lua) to start the greeter automatically. Place the configuration file at `/etc/greetd/qsgreeter-hyprland.lua` (Automatically installed when using `makepkg` on _Arch_) and edit `/etc/greetd/config.toml` to launch Hyprland with the specified configuration:

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

Configuration files are located at `/etc/xdg/quickshell/qsgreeter`. You can customize the look and fell by editing `colorscheme.json` and `style.json`.

Since the greeter is written entirely in **QML**, you can also rearrange elements as you wish.

## 🤖 AI Disclosure
Code was written entirely by me, but AI was used for technical guidance
