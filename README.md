# MX Master Config

Lightweight Swift tools for Logitech MX Master mice on macOS. `hid-logger` prints raw HID usages so you can learn which buttons fire which codes, and `mxmasterd` maps those usages to Mission Control, App Exposé, or arbitrary key combinations without running Logitech's official software, which needs constant web access and excessive permissions. This little project solves the issue of being stuck with LogiOptions and their various other agents. Once this is set up it works well and maintains persistence fine.

## Requirements

- macOS 13 (Ventura) or newer (tested on macOS 16.1 "Tahoe").
- Xcode command-line tools / Swift 5.9+
- Accessibility **and** Input Monitoring permission for the built daemon binary. **This is very Important**
- Tested with a Logitech MX Master 4

## Build

```bash
swift build -c release --product mxmasterd
swift build -c release --product hid-logger
```

The release binaries will be in `.build/release/`.

## Configure button mappings

1. Copy the sample config and edit it to taste:
   ```bash
   mkdir -p ~/.config/mxmaster
   cp config/mappings.sample.json ~/.config/mxmaster/mappings.json
   ```
2. Each key in `buttons` is a HID usage ID (hex or decimal). Values can specify:
   ```json
   {
     "key": "leftBracket",
     "modifiers": ["command", "shift"]
   }
   ```
   or a raw `keyCode` (UInt16) if you prefer.
3. The special key name `"missioncontrol"` launches `/System/Applications/Mission Control.app` instead of emitting a key press.

Use `hid-logger` while pressing MX Master buttons to discover their usages:
```bash
swift run hid-logger
```

## Install the daemon

1. Copy the release binary somewhere stable, e.g. `/usr/local/bin/mxmasterd`.
2. Authorize it in System Settings → Privacy & Security:
   - Accessibility → `+` → select the binary → enable the checkbox.
   - Input Monitoring → `+` → select the binary → enable the checkbox.
3. (Optional - But this worked best for me on Tahoe due to permission issues) Wrap it in a minimal `.app` bundle if you prefer to keep binaries inside `~/Applications`.

## LaunchAgent (run at login)

1. Copy the sample plist and update the absolute path:
   ```bash
   mkdir -p ~/Library/LaunchAgents
   cp LaunchAgents/com.example.mxmasterd.plist ~/Library/LaunchAgents/com.example.mxmasterd.plist
   # edit ProgramArguments[0] so it points to your mxmasterd binary
   ```
2. Load it for your user session:
   ```bash
   launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.example.mxmasterd.plist
   launchctl kickstart -k gui/$UID/com.example.mxmasterd
   ```
3. Logs (if configured in the plist) go to `/tmp/mxmasterd.log` and `/tmp/mxmasterd.err`.

## Updating mappings

Edit `~/.config/mxmaster/mappings.json` at any time, then restart the daemon:
```bash
launchctl kickstart -k gui/$UID/com.example.mxmasterd
```

## License

MIT (add your preferred license before publishing).
