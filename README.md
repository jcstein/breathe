# breathe

A macOS menu bar breathing pacer. 5.5s inhale, 5.5s exhale — the resonant breathing rate from James Nestor's [*Breath*](https://www.mrjamesnestor.com/breath).

A pulsing circle lives in your menu bar. Click it for a larger view with a countdown timer.

## install

```bash
git clone https://github.com/jcstein/breathe.git
cd breathe
swift build -c release
cp .build/release/Breathe /usr/local/bin/breathe
```

Then run `breathe`.

### auto-launch on login

System Settings → General → Login Items → "+" → Cmd+Shift+G → `/usr/local/bin/breathe` → Add.

## requirements

- macOS 13+
- Swift 5.9+
