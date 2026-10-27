# kde-nightlight-toggle

A one-click Night Light toggle for KDE Plasma 6 that **always starts switched off** after a restart.

KDE's built-in Night Light control is a "suspend" that resets on login, so you end up with an orange screen after every reboot. This project adds a toggle button and a small login script that turns Night Light off at startup. You turn it on only when you want it.

Works on Wayland and X11.

## Requirements

- KDE Plasma 6
- `qdbus6`, `busctl` and `kwriteconfig6` (all ship with Plasma 6 on most distros)

On Plasma 5 the tool names differ (`qdbus`, `kwriteconfig5`), so this will not work without edits.

## Install

```bash
git clone https://github.com/nitrokryptic/kde-nightlight-toggle.git
cd kde-nightlight-toggle
bash install.sh
```

If you use fish or another non-bash shell, keep the `bash` in front of the command. The script uses bash syntax.

Then pin the launcher:

1. Open the app launcher and search **Night Light Toggle**.
2. Right-click it and choose **Pin to Task Manager**.

Optional: bind a key under System Settings → Keyboard → Shortcuts → Add New → Command or Script, pointing at `~/.local/bin/nightlight-toggle`.

## Usage

- Click the pinned button (or press your shortcut) to toggle Night Light.
- Reboot, and Night Light comes up off after about 8 seconds.

Set your preferred colour temperature once in System Settings → Display & Monitor → Night Light. The toggle uses whatever you set there.

## What it installs

| File | Purpose |
| --- | --- |
| `~/.local/bin/nightlight-toggle` | Toggles Night Light |
| `~/.local/bin/nightlight-boot-off` | Suspends Night Light after login if it is running |
| `~/.local/share/applications/nightlight-toggle.desktop` | Launcher you can pin |
| `~/.config/autostart/nightlight-boot-off.desktop` | Runs the boot script at login |

## How it works

KWin exposes the same action as the tray's suspend button as a global shortcut, **Toggle Night Color**. The toggle script triggers it over D-Bus:

```bash
qdbus6 org.kde.kglobalaccel /component/kwin invokeShortcut "Toggle Night Color"
```

Editing `Active` or `NightTemperature` in `kwinrc` does not reliably change the live state, so this project does not use that approach.

Because suspend state does not survive a restart, the boot script waits for KWin, reads the live `inhibited` property, and fires the toggle only if Night Light is not already suspended:

```bash
busctl --user get-property org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight inhibited
```

## Limitations

- It always boots off. It cannot remember the state you left it in.
- The boot script waits 8 seconds for KWin to be ready, so you may see a brief orange flash at login. If it fires too early on a slow machine, raise the `sleep 8` value in `~/.local/bin/nightlight-boot-off`.
- Don't mix this with the tray's suspend button. They share the same state and will confuse each other.

## Troubleshooting

**The button does nothing.** Run the toggle in a terminal and look for errors:

```bash
~/.local/bin/nightlight-toggle
```

**Check that the shortcut exists:**

```bash
qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.shortcutNames | grep -i night
```

**Still orange after login.** Confirm the autostart files exist:

```bash
ls -l ~/.config/autostart/nightlight-boot-off.desktop ~/.local/bin/nightlight-boot-off
```

**Check KWin's live state:**

```bash
busctl --user get-property org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight inhibited
```

`b true` means suspended (off). `b false` means active.

## Uninstall

```bash
bash install.sh --uninstall
```

## License

MIT
