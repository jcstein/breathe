# breathe

A macOS menu bar breathing pacer. 5.5s inhale, 5.5s exhale — the resonant breathing rate from James Nestor's [*Breath*](https://www.mrjamesnestor.com/breath).

A pulsing circle lives in your menu bar. Click it for a larger view with a countdown timer.

## install

Download `Breathe-v1.1.0-macos.zip` from the [latest release](https://github.com/jcstein/breathe/releases/latest), unzip it, and move `Breathe.app` to your Applications folder.

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
