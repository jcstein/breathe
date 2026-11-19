#!/bin/bash
set -eu
set -o pipefail

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

[ "$(uname -s)" = Darwin ] || die 'Breathe requires macOS.'

temp_dir=$(mktemp -d) || die 'Could not create a temporary directory.'
trap 'rm -rf "$temp_dir"' EXIT
trap 'exit 1' HUP INT TERM

printf 'Finding the latest Breathe release...\n'
metadata=$(curl -fsSL https://api.github.com/repos/jcstein/breathe/releases/latest) \
    || die 'Could not fetch the latest release from GitHub.'
asset_url=$(printf '%s\n' "$metadata" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\(https:\/\/[^"[:space:]]*-macos\.zip\)".*/\1/p' | head -n 1)
[ -n "$asset_url" ] || die 'The latest release has no macOS zip asset.'

printf 'Downloading %s...\n' "$asset_url"
curl -fsSL "$asset_url" -o "$temp_dir/Breathe.zip" \
    || die 'Could not download the Breathe release.'
ditto -x -k "$temp_dir/Breathe.zip" "$temp_dir/unpacked" \
    || die 'Could not extract the Breathe release.'
[ -d "$temp_dir/unpacked/Breathe.app" ] || die 'The release does not contain Breathe.app.'

install_dir=/Applications
if [ ! -w "$install_dir" ] || { [ -e "$install_dir/Breathe.app" ] && [ ! -w "$install_dir/Breathe.app" ]; }; then
    install_dir="$HOME/Applications"
    mkdir -p "$install_dir" || die 'Could not create ~/Applications.'
fi
[ -w "$install_dir" ] || die "Cannot write to $install_dir."

if pgrep -x Breathe >/dev/null; then
    osascript -e 'tell application "Breathe" to quit' \
        || die 'Could not quit Breathe. Quit it and run this installer again.'
fi

app_path="$install_dir/Breathe.app"
rm -rf "$app_path" || die "Could not remove the existing $app_path."
ditto "$temp_dir/unpacked/Breathe.app" "$app_path" \
    || die "Could not install Breathe to $app_path."
xattr -dr com.apple.quarantine "$app_path" 2>/dev/null || true

printf 'Installed Breathe to %s\n' "$app_path"
printf 'To open it, run: open "%s"\n' "$app_path"
