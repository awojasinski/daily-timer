import Foundation

public enum ToastOutcome: String, CaseIterable, Sendable {
    case raw = "RAW"
    case nailed = "NAILED"
    case burnt = "BURNT"
}

public enum TimerPhase: Sendable {
    case idle, running, paused, summary
}

public struct TimerReading: Sendable {
    public let elapsed: TimeInterval
    public let progress: Double
    public let outcome: ToastOutcome
    public let text: String
    public let ejectionElapsed: TimeInterval?
}

public struct ToastSession: Sendable {
    public static let defaultBudgetSeconds = 60
    public static let budgetRange = 15...3600
    public private(set) var budgetSeconds: Int
    public private(set) var phase: TimerPhase = .idle
    public private(set) var tally: [ToastOutcome: Int] = [:]
    public private(set) var totalSpeakingTime: TimeInterval = 0
    private var accumulated: TimeInterval = 0
    private var startedAt: TimeInterval?
    private var turnBudget: Int
    private var deadlineConsumed = false
    private var ejectedAt: TimeInterval?

    public init(budgetSeconds: Int = ToastSession.defaultBudgetSeconds) {
        let budget = Self.budgetRange.contains(budgetSeconds) ? budgetSeconds : Self.defaultBudgetSeconds
        self.budgetSeconds = budget
        self.turnBudget = budget
    }

    @discardableResult
    public mutating func setBudget(seconds: Int) -> Bool {
        guard phase == .idle,
              Self.budgetRange.contains(seconds) else { return false }
        budgetSeconds = seconds
        if phase == .idle { turnBudget = seconds }
        return true
    }

    public mutating func start(at now: TimeInterval) {
        guard phase == .idle else { return }
        accumulated = 0
        startedAt = now
        turnBudget = budgetSeconds
        deadlineConsumed = false
        ejectedAt = nil
        phase = .running
    }

    public mutating func pause(at now: TimeInterval) {
        guard phase == .running else { return }
        accumulated = elapsed(at: now)
        startedAt = nil
        phase = .paused
    }

    public mutating func resume(at now: TimeInterval) {
        guard phase == .paused else { return }
        startedAt = now
        phase = .running
    }

    @discardableResult
    public mutating func finish(at now: TimeInterval) -> ToastOutcome? {
        guard let outcome = endMeeting(at: now) else { return nil }
        phase = .idle
        start(at: now)
        return outcome
    }

    @discardableResult
    public mutating func endMeeting(at now: TimeInterval) -> ToastOutcome? {
        guard phase == .running || phase == .paused else { return nil }
        let outcome = reading(at: now).outcome
        accumulated = elapsed(at: now)
        totalSpeakingTime += accumulated
        tally[outcome, default: 0] += 1
        startedAt = nil
        phase = .summary
        return outcome
    }

    public mutating func resetMeeting() {
        self = ToastSession(budgetSeconds: budgetSeconds)
    }

    public func elapsed(at now: TimeInterval) -> TimeInterval {
        accumulated + (startedAt.map { max(0, now - $0) } ?? 0)
    }

    public func reading(at now: TimeInterval) -> TimerReading {
        let elapsed = elapsed(at: now)
        let budget = Double(turnBudget)
        let outcome: ToastOutcome = elapsed < budget * 0.8 ? .raw : elapsed <= budget ? .nailed : .burnt
        let remaining = phase == .summary ? totalSpeakingTime : budget - elapsed
        let seconds = Int(ceil(abs(remaining)))
        let text = String(format: "%@%02d:%02d", remaining < 0 ? "+" : "", seconds / 60, seconds % 60)
        return TimerReading(elapsed: elapsed, progress: elapsed / budget, outcome: outcome, text: text,
                            ejectionElapsed: ejectedAt.map { max(0, now - $0) })
    }

    public mutating func consumeDeadline(at now: TimeInterval) -> Bool {
        guard phase == .running, !deadlineConsumed,
              elapsed(at: now) >= Double(turnBudget) else { return false }
        deadlineConsumed = true
        ejectedAt = now
        return true
    }
}
