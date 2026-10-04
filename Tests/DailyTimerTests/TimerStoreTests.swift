import Foundation
import Testing
import TimerCore
@testable import DailyTimer

@Test @MainActor func finishSoundsAndStartsNext() {
    let domain = "io.tinytoast.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    var now = 0.0
    var cues: [TimerCue] = []
    let store = TimerStore(defaults: defaults, clock: { now }, playSound: { cues.append($0) })
    #expect(store.soundEnabled)
    store.primaryAction()
    now = 50
    store.finish()
    #expect(cues == [.finish])
    #expect(store.session.phase == .running)
    #expect(store.reading.text == "01:00")
    now = 52
    store.refresh()
    #expect(store.reading.text == "00:58")
}

@Test @MainActor func deadlineSoundsOnceAndFinishingDoesNotDoubleRing() {
    let domain = "io.tinytoast.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    var now = 0.0
    var cues: [TimerCue] = []
    let store = TimerStore(defaults: defaults, clock: { now }, playSound: { cues.append($0) })
    store.primaryAction()
    now = 60
    store.refresh()
    store.refresh()
    #expect(cues == [.deadline])
    now = 60.5
    store.finish()
    #expect(cues == [.deadline, .finish])
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
    var cues: [TimerCue] = []
    let store = TimerStore(defaults: defaults, clock: { now }, playSound: { cues.append($0) })
    store.primaryAction()
    now = 61
    store.refresh()
    store.finish(endingMeeting: true)
    now = 200
    store.refresh()
    #expect(cues.isEmpty)
    #expect(store.session.phase == .summary)
    #expect(store.session.exceededCount == 0)
    store.primaryAction()
    #expect(store.session.phase == .idle)
    #expect(store.reading.text == "01:00")
}

@Test @MainActor func stopCountsLastSpeakerOnce() {
    let domain = "io.tinytoast.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    var now = 0.0
    var cues: [TimerCue] = []
    let store = TimerStore(defaults: defaults, clock: { now }, playSound: { cues.append($0) })
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
    now = 300
    store.refresh()
    #expect(store.session.phase == .summary)
    #expect(store.session.exceededCount == 0)
}

@Test @MainActor func systemSoundsAreAvailable() {
    #expect(TimerAudio.sounds.count == TimerCue.allCases.count)
    for sound in TimerAudio.sounds.values {
        #expect(sound.duration > 0)
    }
}

@Test @MainActor func nextAfterOvertimeRecordsPersonAndRestartsDeadline() {
    let domain = "io.tinytoast.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    var now = 0.0
    var cues: [TimerCue] = []
    let store = TimerStore(defaults: defaults, clock: { now }, playSound: { cues.append($0) })
    store.primaryAction()
    now = 70
    store.refresh()
    #expect(store.reading.status == .red)
    store.finish()
    #expect(store.session.exceededCount == 1)
    #expect(store.session.phase == .running)
    #expect(store.reading.text == "01:00")
    #expect(store.reading.status == .neutral)
    now = 130
    store.refresh()
    #expect(cues == [.deadline, .finish, .deadline])
}
