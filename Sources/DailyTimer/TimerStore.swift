import AppKit
import Combine
import TimerCore

enum TimerCue: String, CaseIterable {
    case deadline = "Glass"
    case finish = "Pop"
}

@MainActor
enum TimerAudio {
    static let sounds: [TimerCue: NSSound] = Dictionary(uniqueKeysWithValues: TimerCue.allCases.compactMap { cue in
        guard let sound = NSSound(named: NSSound.Name(cue.rawValue)) else { return nil }
        return (cue, sound)
    })
}

@MainActor
final class TimerStore: ObservableObject {
    @Published private(set) var session: TimerSession
    @Published private(set) var reading: TimerReading
    @Published var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    private let defaults: UserDefaults
    private let clock: () -> TimeInterval
    private let playSound: (TimerCue) -> Void
    private var updates: Task<Void, Never>?

    init(defaults: UserDefaults = .standard, clock: (() -> TimeInterval)? = nil,
         playSound: @escaping (TimerCue) -> Void = { cue in
             TimerAudio.sounds[cue]?.stop()
             TimerAudio.sounds[cue]?.play()
         }) {
        self.defaults = defaults
        let origin = ContinuousClock.now
        self.clock = clock ?? {
            let duration = origin.duration(to: .now).components
            return Double(duration.seconds) + Double(duration.attoseconds) / 1e18
        }
        self.playSound = playSound
        let savedBudget = defaults.object(forKey: "budgetSeconds") as? Int ?? TimerSession.defaultBudgetSeconds
        let session = TimerSession(budgetSeconds: (10..<TimerSession.budgetRange.lowerBound).contains(savedBudget)
                                   ? TimerSession.budgetRange.lowerBound : savedBudget)
        self.session = session
        self.reading = session.reading(at: 0)
        self.soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        updates = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                self?.refresh()
            }
        }
    }

    deinit { updates?.cancel() }

    var summary: String {
        let count = session.exceededCount
        return count == 1 ? "1 person exceeded their time" : "\(count) people exceeded their time"
    }

    func primaryAction() {
        let timestamp = clock()
        soundDeadline(at: timestamp)
        switch session.phase {
        case .idle: session.start(at: timestamp)
        case .running: session.pause(at: timestamp)
        case .paused: session.resume(at: timestamp)
        case .summary: resetMeeting()
        }
        reading = session.reading(at: timestamp)
    }

    func finish(endingMeeting: Bool = false) {
        let timestamp = clock()
        let finished = endingMeeting ? session.endMeeting(at: timestamp) : session.finish(at: timestamp)
        guard finished else { return }
        if soundEnabled { playSound(.finish) }
        reading = session.reading(at: timestamp)
    }

    func resetMeeting() {
        session.resetMeeting()
        reading = session.reading(at: clock())
    }

    @discardableResult
    func setBudget(seconds: Int) -> Bool {
        guard session.setBudget(seconds: seconds) else { return false }
        defaults.set(seconds, forKey: "budgetSeconds")
        reading = session.reading(at: clock())
        return true
    }

    func refresh() {
        guard session.phase == .running else { return }
        let timestamp = clock()
        soundDeadline(at: timestamp)
        reading = session.reading(at: timestamp)
    }

    private func soundDeadline(at timestamp: TimeInterval) {
        if session.consumeDeadline(at: timestamp), soundEnabled { playSound(.deadline) }
    }
}
