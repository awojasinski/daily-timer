#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

build_flags=(-c release)
if [[ -n "${SDKROOT:-}" ]]; then
    build_flags+=(--sdk "$SDKROOT")
fi
swift build "${build_flags[@]}" --product TinyToast
swift build "${build_flags[@]}" --product ToastAssets
bin_dir=$(swift build "${build_flags[@]}" --show-bin-path)
app="dist/Tiny Toast.app"
resources="$app/Contents/Resources"
iconset=".build/Toast.iconset"
mkdir -p "$app/Contents/MacOS" "$resources" "$iconset"
cp "$bin_dir/TinyToast" "$app/Contents/MacOS/TinyToast.next"
mv -f "$app/Contents/MacOS/TinyToast.next" "$app/Contents/MacOS/TinyToast"
"$bin_dir/ToastAssets" .build/artwork

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" .build/artwork/Icon.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" .build/artwork/Icon.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$resources/Toast.icns"
cp Resources/Info.plist "$app/Contents/Info.plist"
printf 'APPL????' > "$app/Contents/PkgInfo"
codesign --force --sign - "$app"
codesign --verify --strict "$app"
printf '\nFresh toast: %s/%s\n' "$PWD" "$app"
