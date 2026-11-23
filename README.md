# breathe

A macOS menu bar breathing pacer. 5.5s inhale, 5.5s exhale — the resonant breathing rate from James Nestor's [*Breath*](https://www.mrjamesnestor.com/breath).

A pulsing circle lives in your menu bar. Click it for a larger view with a countdown timer.

The larger view also lets you switch to box breathing: 4s inhale, 4s hold, 4s exhale, 4s hold. Breathe remembers your choice.

The larger view also shows minutes breathed today, sessions this week, and your daily streak. They are stored only on your Mac: no account, no network.

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

### publish a release

Merged changes reach the installer only once they are released. Tag the commit on `main` and push the tag:

```bash
git tag v1.2.0 && git push origin v1.2.0
```

The Release workflow runs the tests, packages `Breathe-v1.2.0-macos.zip` and publishes it as the latest GitHub release, which `install.sh` downloads.

To package locally instead, run `./package.sh 1.2.0` (or `./package.sh` on a tagged commit). It builds the same ZIP with both bundle versions set to `1.2.0` and refuses to package a version whose tag points at a different commit.

### landing page

`site/` is the static landing page for breathe.jcstein.dev (no build step). Preview it with `python3 -m http.server 8000 --directory site`. It is the `breathe` Cloudflare Worker (custom domain breathe.jcstein.dev), configured in `wrangler.jsonc`. Cloudflare Workers Builds deploys it whenever a change to `site/` or `wrangler.jsonc` lands on `main`; to deploy by hand, run:

```bash
npx wrangler deploy
```

The "Coming soon on TestFlight" button is a disabled placeholder. To open it, edit the `data-checkout` link in `site/index.html`: add `href="<TestFlight or checkout URL>"`, set its label, remove `is-pending`, `aria-disabled` and `role`, and delete the `data-checkout-note` line.

### auto-launch on login

System Settings → General → Login Items → "+" → select Breathe from Applications.

## requirements

- macOS 13+
- Apple Silicon (arm64)
