#!/bin/bash
# Builds Breathe-v<version>-macos.zip, the release asset site/install.sh downloads.
# Usage: ./package.sh [version]   e.g. ./package.sh 1.2.0 or ./package.sh v1.2.0
# Without a version, uses the tag on HEAD.
set -eu
set -o pipefail

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

cd "$(dirname "$0")"

version=${1:-$(git describe --tags --exact-match 2>/dev/null)} \
    || die 'HEAD has no tag. Pass a version, e.g. ./package.sh 1.2.0'
version=${version#v}
[[ $version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] \
    || die "Invalid version '$version'. Use the form 1.2.0."
tag="v$version"

if tag_commit=$(git rev-parse -q --verify "refs/tags/$tag^{commit}"); then
    [ "$tag_commit" = "$(git rev-parse HEAD)" ] \
        || die "Tag $tag exists but is not HEAD. Check it out before packaging."
fi

swift build -c release --arch arm64
bin_dir=$(swift build -c release --arch arm64 --show-bin-path)

stage_dir=$(mktemp -d)
trap 'rm -rf "$stage_dir"' EXIT
app="$stage_dir/Breathe.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/Breathe" "$app/Contents/MacOS/Breathe"
cp Sources/Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Breathe</string>
    <key>CFBundleDisplayName</key>
    <string>Breathe</string>
    <key>CFBundleIdentifier</key>
    <string>com.jcstein.breathe</string>
    <key>CFBundleVersion</key>
    <string>$version</string>
    <key>CFBundleShortVersionString</key>
    <string>$version</string>
    <key>CFBundleExecutable</key>
    <string>Breathe</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST
plutil -lint -s "$app/Contents/Info.plist"

codesign --force --sign - "$app"

zip="Breathe-$tag-macos.zip"
rm -f "$zip"
ditto -c -k --keepParent "$app" "$zip"
printf 'Built %s (version %s)\n' "$zip" "$version"
