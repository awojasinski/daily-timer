import AppKit
import Combine
import ToastCore
import ToastArt

enum ToastCue: String {
    case deadline = "Glass"
    case finish = "Pop"
}

@MainActor
final class ToastStore: ObservableObject {
    @Published private(set) var session: ToastSession
    @Published private(set) var reading: TimerReading
    @Published private(set) var serving: TimerReading?
    @Published private(set) var servingElapsed: Double?
    @Published var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    private let defaults: UserDefaults
    private let clock: () -> TimeInterval
    private let playSound: (ToastCue) -> Void
    private var servingStartedAt: TimeInterval?
    private var updates: Task<Void, Never>?

    init(defaults: UserDefaults = .standard, clock: (() -> TimeInterval)? = nil,
         playSound: @escaping (ToastCue) -> Void = { NSSound(named: $0.rawValue)?.play() }) {
        self.defaults = defaults
        let origin = ContinuousClock.now
        self.clock = clock ?? {
            let duration = origin.duration(to: .now).components
            return Double(duration.seconds) + Double(duration.attoseconds) / 1e18
        }
        self.playSound = playSound
        let savedBudget = defaults.object(forKey: "budgetSeconds") as? Int ?? ToastSession.defaultBudgetSeconds
        let session = ToastSession(budgetSeconds: (10..<ToastSession.budgetRange.lowerBound).contains(savedBudget)
                                   ? ToastSession.budgetRange.lowerBound : savedBudget)
        self.session = session
        self.reading = session.reading(at: 0)
        self.soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        updates = Task { [weak self] in
            while !Task.isCancelled {
                let animating = self?.serving != nil || self?.reading.ejectionElapsed.map { $0 < ToastPop.duration } == true
                do { try await Task.sleep(for: .milliseconds(animating ? 33 : 100)) } catch { return }
                self?.refresh()
            }
        }
    }

    deinit { updates?.cancel() }

    var caption: String {
        if session.phase == .idle { return "Small timer. Strong bread opinions." }
        if session.phase == .paused { return "Bread break. Take your time." }
        if session.phase == .summary { return "Meeting served. Crumbs accounted for." }
        switch reading.outcome {
        case .raw: return "Warming up the daily bread…"
        case .nailed: return "Crisp update. No crumbs."
        case .burnt: return "This update has become a podcast."
        }
    }

    var characterReading: TimerReading { serving ?? reading }
    var characterEjection: Double? { serving == nil ? reading.ejectionElapsed : servingElapsed }
    var characterLowered: Bool {
        (session.phase == .running || session.phase == .paused) && characterEjection == nil
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
        let previous = session.reading(at: timestamp)
        let outcome = endingMeeting ? session.endMeeting(at: timestamp) : session.finish(at: timestamp)
        guard outcome != nil else { return }
        if soundEnabled { playSound(.finish) }
        let elapsed = previous.ejectionElapsed ?? 0
        if elapsed < ToastPop.duration {
            serving = previous
            servingStartedAt = timestamp - elapsed
            servingElapsed = elapsed
        } else {
            serving = nil
            servingStartedAt = nil
            servingElapsed = nil
        }
        reading = session.reading(at: timestamp)
    }

    func resetMeeting() {
        session.resetMeeting()
        serving = nil
        servingElapsed = nil
        servingStartedAt = nil
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
        guard session.phase == .running || serving != nil || reading.ejectionElapsed.map({ $0 < ToastPop.duration }) == true else { return }
        let timestamp = clock()
        soundDeadline(at: timestamp)
        reading = session.reading(at: timestamp)
        if let start = servingStartedAt {
            if timestamp - start >= ToastPop.duration {
                serving = nil
                servingElapsed = nil
                servingStartedAt = nil
            } else {
                servingElapsed = timestamp - start
            }
        }
    }

    private func soundDeadline(at timestamp: TimeInterval) {
        if session.consumeDeadline(at: timestamp), soundEnabled { playSound(.deadline) }
    }
}
