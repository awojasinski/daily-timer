#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
series=$(cat VERSION)
test "$(bash scripts/release-version.sh 42)" = "$series.42"
test "$(bash scripts/release-version.sh)" = "$series.0"
if bash scripts/release-version.sh invalid >/dev/null 2>&1; then
    echo 'Invalid build number was accepted.' >&2
    exit 1
fi
for event in pull_request workflow_dispatch; do
    if GITHUB_EVENT_NAME="$event" GITHUB_REF=refs/heads/main bash scripts/publish-release.sh >/dev/null 2>&1; then
        echo "$event unexpectedly permitted publishing." >&2
        exit 1
    fi
done
if GITHUB_EVENT_NAME=push GITHUB_REF=refs/heads/feature bash scripts/publish-release.sh >/dev/null 2>&1; then
    echo 'Feature branch unexpectedly permitted publishing.' >&2
    exit 1
fi
printf 'Release version and trigger checks passed.\n'

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/scripts" "$fixture/release-assets" "$fixture/bin"
cp scripts/publish-release.sh scripts/release-version.sh "$fixture/scripts/"
cp VERSION "$fixture/"
version=$(bash scripts/release-version.sh 42)
for arch in arm64 x86_64; do
    archive="daily-timer-${version}-macos-${arch}.zip"
    printf 'Test archive for %s\n' "$arch" > "$fixture/release-assets/$archive"
    (cd "$fixture/release-assets" && shasum -a 256 "$archive" > "$archive.sha256")
done
cat > "$fixture/bin/gh" <<'MOCK'
#!/bin/bash
printf '%s\n' "$*" >> "$TEST_GH_LOG"
case "$1 $2" in
    'release view')
        if [[ "${TEST_PUBLISHED:-false}" == true ]]; then printf 'false\n'; else exit 1; fi ;;
    'release upload') [[ "${TEST_FAIL_UPLOAD:-false}" != true ]] ;;
    'api '*) printf '%s\n' "$GITHUB_SHA" ;;
esac
MOCK
chmod +x "$fixture/bin/gh"
export PATH="$fixture/bin:$PATH"
export TEST_GH_LOG="$fixture/gh.log"
export GITHUB_EVENT_NAME=push GITHUB_REF=refs/heads/main GITHUB_RUN_NUMBER=42
export GITHUB_SHA=0123456789abcdef0123456789abcdef01234567
export GH_REPO=example/test GH_TOKEN=test-only-not-a-token

TEST_FAIL_UPLOAD=true bash "$fixture/scripts/publish-release.sh" >/dev/null 2>&1 && {
    echo 'Failed upload unexpectedly succeeded.' >&2; exit 1;
}
if grep -q 'release edit' "$TEST_GH_LOG"; then
    echo 'Release was published before its uploads succeeded.' >&2
    exit 1
fi
: > "$TEST_GH_LOG"
TEST_PUBLISHED=true bash "$fixture/scripts/publish-release.sh" >/dev/null
grep -q "release edit v$version --latest$" "$TEST_GH_LOG" || {
    echo 'Retry did not reconcile Latest for a published release.' >&2; exit 1;
}
if grep -q 'release upload' "$TEST_GH_LOG"; then
    echo 'Retry modified already-published assets.' >&2
    exit 1
fi
: > "$TEST_GH_LOG"
bash "$fixture/scripts/publish-release.sh" >/dev/null
grep -q "release create v$version --target $GITHUB_SHA" "$TEST_GH_LOG"
grep -q "release edit v$version --draft=false --latest=false" "$TEST_GH_LOG"
printf 'Release upload ordering and retry checks passed.\n'
