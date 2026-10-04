#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(bash scripts/release-version.sh "${BUILD_NUMBER:-0}")
build_number=${BUILD_NUMBER:-0}
build_flags=(-c release)
if [[ -n "${SDKROOT:-}" ]]; then
    build_flags+=(--sdk "$SDKROOT")
fi
swift build "${build_flags[@]}" --product DailyTimer
swift build "${build_flags[@]}" --product TimerAssets
bin_dir=$(swift build "${build_flags[@]}" --show-bin-path)
staging=$(mktemp -d .build/package.XXXXXX)
trap 'rm -rf "$staging"' EXIT
app="$staging/Daily timer.app"
resources="$app/Contents/Resources"
iconset=".build/DailyTimer.iconset"
mkdir -p "$app/Contents/MacOS" "$resources" "$iconset"
cp "$bin_dir/DailyTimer" "$app/Contents/MacOS/DailyTimer.next"
mv -f "$app/Contents/MacOS/DailyTimer.next" "$app/Contents/MacOS/DailyTimer"
"$bin_dir/TimerAssets" .build/artwork

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" .build/artwork/Icon.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" .build/artwork/Icon.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$resources/DailyTimer.icns"
cp LICENSE "$resources/LICENSE"
cp Resources/Info.plist "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$app/Contents/Info.plist"
printf 'APPL????' > "$app/Contents/PkgInfo"
codesign --force --sign - "$app"
codesign --verify --strict "$app"
mkdir -p dist
if [[ -d "dist/Daily timer.app" ]]; then
    mv "dist/Daily timer.app" "$staging/Previous.app"
fi
mv "$app" "dist/Daily timer.app"
printf '\nPackaged timer: %s/dist/Daily timer.app\n' "$PWD"

architecture=$(uname -m)
archive="daily-timer-${version}-macos-${architecture}.zip"
(cd dist && ditto -c -k --sequesterRsrc --keepParent "Daily timer.app" "$archive")
(cd dist && shasum -a 256 "$archive" > "$archive.sha256")
printf 'Release archive: dist/%s\n' "$archive"
