import Foundation
import Testing
import ToastCore
@testable import TinyToast

@Test @MainActor func finishSoundsAndStartsNextWhileServingPreviousToast() {
    let domain = "io.tinytoast.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    var now = 0.0
    var cues: [ToastCue] = []
    let store = ToastStore(defaults: defaults, clock: { now }, playSound: { cues.append($0) })
    #expect(store.soundEnabled)
    store.primaryAction()
    now = 50
    store.finish()
    #expect(cues == [.finish])
    #expect(store.session.phase == .running)
    #expect(store.reading.text == "01:00")
    #expect(store.session.tally[.nailed] == 1)
    #expect(store.serving?.outcome == .nailed)
    #expect(store.servingElapsed == 0)
    now = 52
    store.refresh()
    #expect(store.reading.text == "00:58")
    #expect(store.serving == nil)
    #expect(store.servingElapsed == nil)
}

@Test @MainActor func deadlineSoundsOnceAndFinishingDoesNotDoubleRing() {
    let domain = "io.tinytoast.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    var now = 0.0
    var cues: [ToastCue] = []
    let store = ToastStore(defaults: defaults, clock: { now }, playSound: { cues.append($0) })
    store.primaryAction()
    now = 60
    store.refresh()
    store.refresh()
    #expect(cues == [.deadline])
    now = 60.5
    store.finish()
    #expect(cues == [.deadline, .finish])
    #expect(store.servingElapsed == 0.5)
    now = 120.5
    store.finish()
    #expect(cues == [.deadline, .finish, .finish])
}

@Test @MainActor func muteAndSummaryStopSoundAndScoring() {
    let domain = "io.tinytoast.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    defaults.set(false, forKey: "soundEnabled")
    var now = 0.0
    var cues: [ToastCue] = []
    let store = ToastStore(defaults: defaults, clock: { now }, playSound: { cues.append($0) })
    store.primaryAction()
    now = 61
    store.refresh()
    store.finish(endingMeeting: true)
    now = 200
    store.refresh()
    #expect(cues.isEmpty)
    #expect(store.session.phase == .summary)
    #expect(store.session.tally == [.burnt: 1])
    store.primaryAction()
    #expect(store.session.phase == .idle)
    #expect(store.session.tally.isEmpty)
    #expect(store.reading.text == "01:00")
}

@Test @MainActor func stopServesLastSpeakerOnceAndShowsTotalTime() {
    let domain = "io.tinytoast.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    var now = 0.0
    var cues: [ToastCue] = []
    let store = ToastStore(defaults: defaults, clock: { now }, playSound: { cues.append($0) })
    store.primaryAction()
    now = 50
    store.finish()
    now = 70
    store.primaryAction()
    now = 100
    store.primaryAction()
    now = 140
    store.finish(endingMeeting: true)
    store.finish(endingMeeting: true)
    #expect(cues == [.finish, .finish])
    #expect(store.session.tally == [.nailed: 2])
    #expect(store.session.totalSpeakingTime == 110)
    #expect(store.reading.text == "01:50")
    now = 300
    store.refresh()
    #expect(store.reading.text == "01:50")
    #expect(store.session.phase == .summary)
}
