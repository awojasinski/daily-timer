# Tiny Toast implementation

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
