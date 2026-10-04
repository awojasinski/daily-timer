# Daily timer implementation history

Approved brief: native SwiftUI/AppKit reusable stand-up timer; draggable translucent
260 × 252 panel above normal browser windows. RAW below 80%, NAILED through 100%,
BURNT after the deadline. Manual finish and anonymous session tally. Original
toaster artwork, optional deadline ding (off initially), local preferences only.

## Work sequence

1. Pure timer/session model and deterministic tests.
2. SwiftUI toaster and AppKit floating panel/menu bar, local settings.
3. Reproducible app packaging and icon, documentation, verification and review.

## Decisions and progress

- Empty repository: use a feature branch in the provided checkout; no initial
  commit exists from which to create a conventional worktree.
- Keep commits pending user review, as requested by the repository instructions.
- Use a monotonic elapsed-time input in the core, driven by ContinuousClock in
  the app. UI refresh cadence never determines elapsed time.
- No full-screen overlay support in v1, per user choice.
- No signed distribution identity required: package and ad-hoc sign for local use.
- Ruling: increase the approximate 220-point height to 252 to keep controls,
  captions and tally readable without increasing width.
- Timer tests: nine tests (including four threshold cases) passed with the
  installed macOS 26.5 SDK and explicit Swift Testing plugin path.
- Fresh code review: no material source findings; native UI verification remains.
- Release package built and ad-hoc signature verified. Binary links only system
  frameworks/libraries. Packaged app is approximately 876 KB on Apple Silicon.
- Native UI: app launched, idle/running layout and settings inspected. Observed
  a live turn and RAW tally; rendered RAW/NAILED/BURNT assets and icon inspected.
- Concurrent user interaction prevented reliable automated UI actions beyond
  opening settings. Focus retention, dragging, Space switching, monitor removal,
  audible ding, and accessibility preference changes remain manual checks.
- Toolchain: default macOS 27 SDK is missing its SwiftUI macro plugin in the
  installed command-line tools. Build against installed macOS 26.5 explicitly;
  see README for repeatable commands. SwiftBuild also emits missing search-path
  warnings for unused developer framework/library directories in these tools.

## Character-only revision

- User requested removal of the card, on-toaster budget controls, and a higher
  automatic deadline pop with a springy landing; confirmed overtime continues.
- The transparent surface is 286 × 286 points including invisible jump headroom.
  The visible toaster is approximately 186 points wide. No OS window shadow.
- The artwork lives in an always-click-through child panel. A small parent
  panel inset entirely within the visible toaster holds controls and dragging.
  Native parent/child movement preserves alignment without mouse polling.
- Review caught a race in the initial polling-based input mask; removed that
  approach so a fast pointer crossing cannot change which app receives a click.
- Minute/second arrows edit the budget between turns. Sound, opacity, anonymous
  tally, reset and hide/quit remain in the menu bar; removed the settings window.
- Ejection timestamp is recorded once at deadline or early finish, independently
  of scoring. A 1.6-second trajectory rises, falls, then settles with a damped
  bounce. Pause/finish cannot restart a deadline pop. Reduce Motion skips it.
- Revision verification: 13 tests passed, release package built and signed, live
  character-only layout inspected with the embedded timer running. Inspected
  rendered apex and landing frames to check headroom. Native drag/click-through
  interaction across other apps still requires a manual check.

## Simplified budget control

- One up/down arrow pair adjusts the total budget by exactly 15 seconds.
- The default and invalid-preference fallback are 60 seconds; existing saved
  custom budgets remain unchanged. Buttons disable before exceeding the limits.

## Continuous meeting and bread dragging

- Finish records one result and starts the next timer immediately, including from
  pause. End Meeting records the current person and displays total speaking time
  and the tally. Pauses are excluded from the total.
  New Meeting clears results and returns to budget setup.
- Sound defaults on, respects a saved mute preference, and has separate deadline
  and finish cues. Finishing at the deadline emits only the finish cue.
- The outgoing bread animation runs independently from the new person's timer.
- Removed opacity preference/UI. A separate bread input window follows the visible
  loaf above the toaster; dragging it moves the parent and both child windows.
  Empty jump space remains click-through.
- Verification: 18 tests passed (15 core/art geometry, 3 store/audio flow).
  Release app rebuilt and ad-hoc signed. Read-only review found no actionable bugs.
  UI automation remained attached to the previous running build and rejected the
  restart action after an app-state change; live bread dragging and audible cues
  are not verified in this revision. Quit/reopen the packaged app to load it.

## Horizontal budget arrows

- Budget setup uses left/decrease and right/increase chevrons around the time.
- Shared core/UI budget range starts at 15 seconds; increments remain 15 seconds.
  Previously saved 10–14 second budgets migrate to 15 seconds on launch.
- Updated timing fixtures to the new minimum; all 18 existing tests pass.

## Stop records the final speaker

- Stop now shares scoring and sound/animation behavior with Finish, then stays in
  summary instead of starting another person. Repeated Stop does not count twice.
- The summary timer shows the sum of all recorded speaking durations, with toast
  counts beneath it. Reset clears the sum; pauses never contribute.
- All 19 tests passed, including stop-at-deadline sound behavior, summed time
  across a paused turn, repeated Stop, and reset.

## Minimal labels, fire, and mechanical sounds

- Removed READY/SERVED and visible action text. During a turn, the outcome sits
  centered above a centered row of icon buttons. Accessible labels remain.
- Above 150% of the per-person budget, vector flames rise around the loaf.
  Pausing and Reduce Motion freeze their flicker; the next person starts fresh.
- Bundled original synthesized cues replace system sounds: a reception bell once
  at overtime entry, and a metallic spring/latch on Finish or Stop. Both honor mute.
- 21 tests pass, including the exact fire threshold and decoding both audio files.

## Soft toy artwork and quieter bell

- User selected soft 3D toy styling. Vector artwork now uses enamel reflections,
  a metal slot and lever, shaded crust and crumb texture, glossy eyes, soft cheeks,
  and an alarmed fire expression. Flames have warm glow and drifting embers.
- Timer display and icon buttons have subtle inset/beveled finishes. Existing
  silhouettes and drag geometry are preserved.
- Reception bell samples are scaled to 30% of their previous amplitude (about
  -10.5 dB). The spring sound stays unchanged. Peak fell from 22455 to 6737.
- Rendered normal and flaming frames inspected; release app rebuilt and signed.

## Painted animation-film character

- Replaced the vector toaster and bread with an original transparent painted atlas
  generated using the built-in image tool. Prompt and provenance: artwork.md.
- Native composition keeps the bread behind the toaster front and in front of its
  rear rim. A shallower resting position keeps the face visible during timing.
- Reception bell reduced another 3.1 dB (now 21% of its initial signal amplitude).
- Sprite resources are bundled into both SwiftPM builds and the standalone app.
  Drag geometry tests sample actual sprite alpha rather than an old vector path.

## Native macOS timer revision

- Replaces the character and three overlapping panels with one native floating
  panel, standard title-bar controls, a system material background, and native
  Liquid Glass buttons on macOS 26+. Older systems use bordered buttons.
- Removes character animation, outcome tally, and total-duration summary from
  the live model. The final result is solely a count of people exceeding 105%.
- Tint is neutral through 80%, yellow above 80% through 95%, orange above 95%
  and below 105%, and red from 105%. Exactly 105% does not increment the count.
- Uses NSSound named Glass and Pop; no audio files or character sprites are
  required by the executable. Old source assets remain unbuilt in the checkout.
- Keeps monotonic timing, immediate next-person flow, pause exclusion, persisted
  settings, menu-bar access, and screen-boundary clamping. Uses a separate saved
  position key because the old position described artwork geometry.
- Replaces the character app icon with a timer symbol. System appearance and
  accessibility settings are honored, with explicit labels and progress values.
- Verification: all 15 tests passed (including 8 color-boundary cases and 4
  budget sizes for strict exceeded counting). Release app built, ad-hoc signed,
  and signature verified; bundle contains only executable, icon, and metadata.
- Live native UI verified: setup, start, pause, resume, red overtime, summary
  with one exceeded person, and return to setup. Read-only code review found no
  actionable issues. Audible output, older-macOS fallback, VoiceOver navigation,
  and alternate system accessibility/appearance settings remain manual checks.
- Installed command-line tools still emit missing developer search-path linker
  warnings; builds and tests succeed using the macOS 26.5 SDK.

## MiniPlayer proportions and focus-aware controls

- Compact 260 × 150-point window with a continuous material surface and subtle
  full-window status tint. Timer and summary stay centered at fixed positions.
- Title, close control, and circular icon buttons fade in only while the window
  is key and the pointer is inside. Tab also reveals controls for keyboard use;
  losing focus resets that keyboard override. Reduce Motion disables the fade.
- First click on an unfocused panel focuses it without activating a timer action.
  AppKit tracking areas handle enter/exit and pointer movement.
- Disables NSHostingView's automatic window sizing and sets the final frame after
  installing content. This removes the hidden title bar's extra 28-point height,
  confirmed in the live 520 × 300 Retina screenshot. Removed the upward offset
  from the timer group after user feedback about vertical centering.
- Tests cover hover-plus-focus gating and keyboard override reset, alongside the
  existing timer suite. Live hidden/revealed layouts inspected; concurrent user
  interaction prevented a controlled end-to-end keyboard/focus test.

## Input tracking and smooth status colors

- Replaced custom NSHostingView tracking callbacks with SwiftUI onHover on the
  fixed outer view. This removes the path where unrelated tracking-area events
  could overwrite whole-panel hover state.
- Mouse-down refreshes pointer position before leaving keyboard-navigation mode.
  The AppKit regression test reproduced the stale-pointer failure before the fix.
- Status tint transitions use a 0.8-second ease-in-out animation, scoped to the
  background color. Reduce Motion keeps immediate changes.
- All 19 tests pass, including the AppKit click regression and advancing after
  red overtime with counting and the next deadline intact. Release bundle built
  and signature verified; read-only review found no additional issues.
- Live automation could not reliably focus the nonactivating panel. The exact
  user-reported overtime click failure still needs confirmation in normal use;
  do not treat the event-state tests as proof of that runtime symptom's cause.

## Daily timer rename, README, and GitHub releases

- Renamed the app, executable, Swift package modules, source/test paths, and icon
  tooling to Daily timer / DailyTimer / TimerCore / TimerAssets. Kept the stable
  bundle identifier to retain existing preferences.
- Added four AppKit renders of the real SwiftUI views to the README, with a
  repeatable opt-in renderer. Renders use a fixed backdrop; desktop glass
  compositing remains system-dependent.
- Added PR/main CI for Apple Silicon and Intel, workflow/script validation,
  signed ZIP packaging with version metadata, and SHA-256 checksums.
- Release publishing consumes the same workflow's tested archives and is gated
  on a successful push to main. Draft-first upload and immutable published-asset
  retries are covered by local release-script tests. Tokens are job-scoped.
- Verified 19 runtime tests, the opt-in renderer, actionlint, release-script tests,
  archive checksum, extracted app signature, metadata, and system-only linkage.
  Intel builds and actual GitHub-hosted execution remain unverified locally.
- Connected the checkout to awojasinski/daily-timer and retained its MIT license.
  No commits, pushes, or GitHub Releases were created during preparation.
