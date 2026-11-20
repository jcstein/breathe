#!/bin/bash
set -eu
set -o pipefail

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

[ "$(uname -s)" = Darwin ] || die 'Breathe requires macOS.'

temp_dir=$(mktemp -d) || die 'Could not create a temporary directory.'
stage_dir=
trap 'rm -rf "$temp_dir"; if [ -n "$stage_dir" ]; then rm -rf "$stage_dir"; fi' EXIT
trap 'exit 1' HUP INT TERM

asset_url=https://breathe.jcstein.dev/download
printf 'Downloading %s...\n' "$asset_url"
curl -fsSL "$asset_url" -o "$temp_dir/Breathe.zip" \
    || die 'Could not download the latest Breathe release.'
ditto -x -k "$temp_dir/Breathe.zip" "$temp_dir/unpacked" \
    || die 'Could not extract the Breathe release.'
[ -d "$temp_dir/unpacked/Breathe.app" ] || die 'The release does not contain Breathe.app.'

install_dir=/Applications
if { [ -e "$install_dir/Breathe.app" ] || [ -L "$install_dir/Breathe.app" ]; } && \
    { [ ! -w "$install_dir" ] || [ ! -w "$install_dir/Breathe.app" ]; }; then
    die 'Cannot replace /Applications/Breathe.app. Remove the old copy (sudo rm -rf /Applications/Breathe.app) and rerun this installer.'
fi
if [ ! -w "$install_dir" ]; then
    install_dir="$HOME/Applications"
    mkdir -p "$install_dir" || die 'Could not create ~/Applications.'
fi
[ -w "$install_dir" ] || die "Cannot write to $install_dir."

stage_dir=$(mktemp -d "$install_dir/.Breathe.XXXXXX") \
    || die "Could not create a staging directory in $install_dir."
ditto "$temp_dir/unpacked/Breathe.app" "$stage_dir/Breathe.app" \
    || die "Could not stage Breathe in $install_dir. The existing app has not been removed."

if pgrep -x Breathe >/dev/null; then
    osascript -e 'tell application "Breathe" to quit' \
        || die 'Could not quit Breathe. Quit it and run this installer again.'
fi

app_path="$install_dir/Breathe.app"
rm -rf "$app_path" || die "Could not remove the existing $app_path."
mv "$stage_dir/Breathe.app" "$app_path" \
    || die "Could not install Breathe to $app_path."
xattr -dr com.apple.quarantine "$app_path" 2>/dev/null || true

printf 'Installed Breathe to %s\n' "$app_path"
printf 'To open it, run: open "%s"\n' "$app_path"
