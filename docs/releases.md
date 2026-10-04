# Release maintenance

The target repository is [awojasinski/daily-timer](https://github.com/awojasinski/daily-timer).
The existing repository license is authoritative; preserve it when integrating
this checkout with the repository's `main` branch.

## Enable the pipeline

1. Commit and push the prepared changes to a branch and open a pull request.
2. Ensure GitHub Actions is enabled. The workflow grants `contents: write` only
   to its release job; repository or organization policy must allow that grant.
3. Protect `main` and require **Validate automation**, **Test and package (arm64)**,
   and **Test and package (x86_64)** before merging. These are recommendations;
   preparing the workflow does not change branch-protection settings.
4. Merge to `main`. The push reruns tests and packaging, then publishes a release
   only when every required job in the workflow succeeds.

Actions are pinned to full commit SHAs. Dependabot proposes updates monthly.
The matrix selects Xcode 26.3 explicitly on `macos-26` and `macos-15-intel`;
review runner availability before changing the toolchain.

## What gets published

- `daily-timer-<version>-macos-arm64.zip`
- `daily-timer-<version>-macos-arm64.zip.sha256`
- `daily-timer-<version>-macos-x86_64.zip`
- `daily-timer-<version>-macos-x86_64.zip.sha256`

The ZIPs preserve the signed app bundle and executable permissions. The release
job downloads artifacts from its own workflow run and verifies both checksums.
It creates a draft at the tested commit, uploads both architectures, then makes
that draft public. A failed upload therefore leaves a draft rather than a
partially populated public release. Developer ID signing and notarization are
not configured; the current builds retain the local ad-hoc signing policy.

The source `VERSION` is `MAJOR.MINOR`. The run number provides a monotonically
increasing patch number within this workflow. PRs consume run numbers too, so
gaps are expected. Change `VERSION` to start a different release series.

## Retries and concurrency

Rerun failed jobs on the original run. Its run number and version stay the same.
An existing draft is completed; a published release is left unchanged. Failed
checks prevent the release job from running at all. Manual workflow dispatch
can test and package a branch but cannot publish a release.

PR runs cancel obsolete runs for that PR. Main pushes are independent. A slower
older build can publish its own version, but it is only marked Latest if its
commit is still the head of `main` when publication completes.

## Local verification

```sh
bash scripts/test-release.sh
go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.12
bash scripts/test.sh
BUILD_NUMBER=42 bash scripts/package.sh
```

The publish script is intended for GitHub Actions. It refuses pull requests,
manual dispatches, and branches other than `main`. Do not put tokens in scripts
or commit credentials. A successful local build does not establish that GitHub's
runners or release permissions have been exercised; inspect the first real run.
