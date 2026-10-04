#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${GITHUB_EVENT_NAME:-}" != push || "${GITHUB_REF:-}" != refs/heads/main ]]; then
    echo 'Releases are only published by a push to main.' >&2
    exit 1
fi
: "${GITHUB_SHA:?Missing tested commit SHA}"
: "${GITHUB_RUN_NUMBER:?Missing CI build number}"
: "${GH_REPO:?Missing GitHub repository}"
: "${GH_TOKEN:?Missing GitHub token}"
version=$(bash scripts/release-version.sh "$GITHUB_RUN_NUMBER")
tag="v$version"

for arch in arm64 x86_64; do
    archive="daily-timer-${version}-macos-${arch}.zip"
    test -s "release-assets/$archive"
    test -s "release-assets/$archive.sha256"
    (cd release-assets && shasum -a 256 -c "$archive.sha256")
done

published=false
if gh release view "$tag" --json isDraft --jq '.isDraft' > release-state.txt 2>/dev/null; then
    if [[ "$(cat release-state.txt)" == false ]]; then
        echo "Release $tag is already published; leaving it unchanged."
        published=true
    fi
else
    cat > release-notes.md <<NOTES
Daily timer $version, built from commit $GITHUB_SHA after both architecture test jobs passed.

- Apple Silicon: download the arm64 ZIP.
- Intel: download the x86_64 ZIP.
- macOS 14 or later; native Liquid Glass controls on macOS 26 or later.
- SHA-256 checksums accompany each archive.

The app is ad-hoc signed, not Developer ID signed or notarized. macOS may require explicit approval to open it.
NOTES
    gh release create "$tag" --target "$GITHUB_SHA" --title "Daily timer $version" \
        --notes-file release-notes.md --draft
fi

if [[ "$published" == false ]]; then
    gh release upload "$tag" release-assets/*.zip release-assets/*.sha256 --clobber
    gh release edit "$tag" --draft=false --latest=false
fi
# An older, slower build must not replace the current main build as Latest.
main_sha=$(gh api "repos/$GH_REPO/git/ref/heads/main" --jq '.object.sha')
if [[ "$main_sha" == "$GITHUB_SHA" ]]; then
    gh release edit "$tag" --latest
fi
