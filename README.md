# breathe

A macOS menu bar breathing pacer. 5.5s inhale, 5.5s exhale — the resonant breathing rate from James Nestor's [*Breath*](https://www.mrjamesnestor.com/breath).

A pulsing circle lives in your menu bar. Click it for a larger view with a countdown timer.

## install

Run this in Terminal to install the latest release:

```bash
curl -fsSL https://raw.githubusercontent.com/jcstein/breathe/main/install.sh | bash
```

The installer quits Breathe if it is running and replaces it in `/Applications` (or `~/Applications` if `/Applications` isn't writable), without sudo. It prints the command to open the app when finished. The app is unsigned and not notarized; this method downloads it without the browser quarantine flag and removes that flag defensively, so no manual `xattr` command is needed. Only run scripts from sources you trust.

### manual download (alternative)

Download the `-macos.zip` asset from the [latest release](https://github.com/jcstein/breathe/releases/latest), unzip it, and move `Breathe.app` to your Applications folder.

Then remove the quarantine flag (required since the app isn't code-signed):

```bash
xattr -cr /Applications/Breathe.app
```

Open `Breathe.app` and you're good to go.

### build from source

```bash
git clone https://github.com/jcstein/breathe.git
cd breathe
swift build -c release
cp .build/release/Breathe /usr/local/bin/breathe
```

### auto-launch on login

System Settings → General → Login Items → "+" → select Breathe from Applications.

## requirements

- macOS 13+
- Apple Silicon (arm64)
