# Tiny Toast

A tiny stand-up timer with strong opinions about long updates. Native macOS 14+
app, built with SwiftUI and AppKit. No accounts, network calls, or dependencies.

## Build and run

Requires Apple's Swift 6 command-line tools (`xcode-select --install`) or Xcode.

```sh
bash scripts/test.sh
bash scripts/package.sh
open "dist/Tiny Toast.app"
```

The packaging script builds for your Mac's architecture and ad-hoc signs the app
for local use. You may move it to Applications. This is not a notarized release
for distribution to other Macs.

`scripts/test.sh` runs `swift test`, adding the installed testing macro plugin
path when present (needed by the Swift 6.4 command-line tools).

If your command-line tools default to a macOS 27 SDK without `SwiftUIMacros`,
select an installed complete SDK explicitly. On the development Mac:

```sh
bash scripts/test.sh --sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk bash scripts/package.sh
```

## At the daily

1. Use the left/right arrows around the timer to adjust the budget by
   15 seconds (minimum 15 seconds; default one minute). Set it once before starting the meeting.
2. Press the **play** button to start. Work in Jira as usual; the timer floats above normal
   windows without requiring browser integration.
3. Pause/resume for interruptions. Press the **checkmark** to finish a speaker and
   immediately start the next person with the same budget.
4. On the last person, press **Stop** to record their toast and end the meeting.
   The timer shows the combined speaking time (excluding pauses), with
   RAW / NAILED / BURNT counts underneath. **New meeting** returns to time setup.

RAW means below 80% of the budget, NAILED means 80–100%, and BURNT means overtime.
At zero, the bread automatically jumps high and lands with a springy bounce.
It pops once per turn; the timer keeps running into overtime. Each finished turn contributes once to the
session tally. **Reset Meeting** clears the tally and discards an unfinished turn.

There is no surrounding card: only the toaster character is visible. Drag its
bread or body to move it. Empty space around it passes clicks to the app underneath.
The menu-bar timer icon offers the session tally, Show/Hide, sound,
Reset Meeting, and Quit. Hiding does not pause the timer.
Budget, sound, and position persist; session results do not survive Quit.
Sleep counts toward elapsed time; pause explicitly to stop timing.

Sound is on initially: a ding at the deadline and a pop on Finish. Mute both from
the menu bar. Reduce Motion replaces the jump with an immediate pop. The character
is fully opaque against a transparent background. It does not overlay
macOS full-screen apps. There are no global keyboard shortcuts to conflict with Jira.

## Code

- `Sources/ToastCore`: deterministic timer state, scoring, and deadline events.
- `Sources/TinyToast`: SwiftUI artwork/UI, observable app state, native panel lifecycle.
- `Tests/ToastCoreTests`: tests use explicit monotonic timestamps, without sleeps.

The visual design uses original SwiftUI vector artwork. The stand-up toast metaphor
was inspired by [Daily Toast](https://dailytoast.io/); this is an independent app.
