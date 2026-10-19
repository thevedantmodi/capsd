# capsd

A tiny macOS daemon that turns Caps Lock into a Hyper key, using only built-in
macOS tools plus [skhd](https://github.com/koekeishiya/skhd) for the shortcuts.

| Action | Result |
|---|---|
| Quick tap alone (under 0.35 s) | Toggles real Caps Lock |
| Hold + another key | Hyper (Cmd+Ctrl+Opt+Shift) + that key |
| Long hold alone | Nothing |

## How it works

1. `hidutil` remaps Caps Lock to F18, so it arrives as an ordinary key.
2. `capsd` installs an event tap, swallows F18, and times the press.
   Any key pressed while F18 is held gets the four Hyper modifier flags.
   A short solo tap toggles Caps Lock through IOKit.
3. skhd matches `hyper - <key>` bindings.

## Install (macOS 12+)

```sh
xcode-select --install
brew install koekeishiya/formulae/skhd

git clone https://github.com/<you>/capsd.git
cd capsd
make install   # builds and copies to ~/bin/capsd
make remap     # Caps Lock -> F18 for this session
```

Grant permissions in System Settings -> Privacy & Security. Add `~/bin/capsd`
and `skhd` (see `which skhd`) under both **Accessibility** and **Input Monitoring**.

```sh
mkdir -p ~/.config/skhd
cp skhdrc.example ~/.config/skhd/skhdrc
skhd --start-service

~/bin/capsd    # test by hand: tap = Caps Lock, hold + T = Terminal. Ctrl+C to stop.
make agents    # once it works: start everything at login
```

## Update

```sh
git pull
make install
make restart
```

Rebuilding changes the binary's signature, so macOS may drop its permissions.
If hotkeys stop working, remove `capsd` from the Accessibility and Input
Monitoring lists, add it again, then run `make restart`.

## Uninstall

```sh
make uninstall
skhd --stop-service
```

## Troubleshooting

- Check the remap: `hidutil property --get "UserKeyMapping"`
- Check it is running: `pgrep capsd`
- capsd output from the launch agent goes to `/tmp/capsd.log`. `Failed: grant
  Accessibility / Input Monitoring` there means `~/bin/capsd` itself needs both
  permissions (running it from a terminal borrows the terminal's).
- Check what skhd receives: `skhd -o`, then hold Caps and press a key.
- Hotkeys die only in a terminal: turn off Secure Keyboard Entry.
- Caps Lock LED does not change: can happen on some external keyboards.
- Tuning: edit `holdThreshold` in `capsd.swift`, then `make install && make restart`.

## Status

Not compiled or tested by the author of this scaffold. Run `~/bin/capsd` by hand
before enabling the launch agents, since `KeepAlive` relaunches it if it crashes.

## MX Master (Logi Options+)

Because Hyper uses the generic modifiers, entering `Cmd+Ctrl+Opt+Shift+T` in the
Custom shortcut field triggers the same `hyper - t` binding.
