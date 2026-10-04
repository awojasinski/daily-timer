import Testing
import Foundation
@testable import TimerCore

@Test(arguments: [
    (0.0, TimerStatus.neutral), (80.0, .neutral), (80.001, .yellow),
    (95.0, .yellow), (95.001, .orange), (104.999, .orange),
    (105.0, .red), (105.001, .red)
])
func timerColorsUseExactBoundaries(elapsed: Double, expected: TimerStatus) {
    var session = TimerSession(budgetSeconds: 100)
    session.start(at: 0)
    #expect(session.reading(at: elapsed).status == expected)
}

@Test(arguments: [15, 60, 100, 3600])
func summaryCountsOnlyStrictlyAbove105Percent(budget: Int) {
    var session = TimerSession(budgetSeconds: budget)
    session.start(at: 0)
    let boundary = Double(budget) * 1.05
    session.finish(at: boundary)
    #expect(session.exceededCount == 0)
    session.endMeeting(at: boundary * 2 + 0.001)
    #expect(session.exceededCount == 1)
    #expect(session.phase == .summary)
    #expect(session.endMeeting(at: 10000) == false)
    #expect(session.finish(at: 10000) == false)
    #expect(session.exceededCount == 1)
}

@Test func finishImmediatelyStartsNextAndResetsColorAndDeadline() {
    var session = TimerSession(budgetSeconds: 100)
    session.start(at: 0)
    #expect(session.consumeDeadline(at: 100) == true)
    #expect(session.finish(at: 110) == true)
    #expect(session.exceededCount == 1)
    #expect(session.phase == .running)
    #expect(session.reading(at: 110).text == "01:40")
    #expect(session.reading(at: 110).status == .neutral)
    #expect(session.consumeDeadline(at: 209) == false)
    #expect(session.consumeDeadline(at: 210) == true)
}

@Test func pauseExcludesTimeAndFinishFromPauseStartsNextRunning() {
    var session = TimerSession()
    session.start(at: 100)
    session.pause(at: 130)
    #expect(session.elapsed(at: 500) == 30)
    session.resume(at: 500)
    #expect(session.elapsed(at: 520) == 50)
    session.pause(at: 520)
    #expect(session.finish(at: 900) == true)
    #expect(session.exceededCount == 0)
    #expect(session.phase == .running)
    #expect(session.elapsed(at: 905) == 5)
}

@Test func endingPausedMeetingCountsSpeakerButExcludesPause() {
    var session = TimerSession()
    #expect(session.endMeeting(at: 0) == false)
    session.start(at: 0)
    session.pause(at: 64)
    session.endMeeting(at: 100)
    #expect(session.phase == .summary)
    #expect(session.exceededCount == 1)
    #expect(session.elapsed(at: 200) == 64)
}

@Test func resetDiscardsUnfinishedTurnAndCountButPreservesBudget() {
    var session = TimerSession(budgetSeconds: 90)
    session.start(at: 0)
    session.finish(at: 100)
    #expect(session.exceededCount == 1)
    session.resetMeeting()
    #expect(session.phase == .idle)
    #expect(session.exceededCount == 0)
    #expect(session.elapsed(at: 300) == 0)
    #expect(session.reading(at: 300).text == "01:30")
    #expect(session.setBudget(seconds: 75) == true)
}

@Test func duplicateStartAndActiveBudgetChangesDoNotResetSpeaker() {
    var session = TimerSession()
    #expect(session.finish(at: 0) == false)
    session.start(at: 10)
    session.start(at: 20)
    #expect(session.elapsed(at: 30) == 20)
    #expect(session.setBudget(seconds: 90) == false)
    session.pause(at: 30)
    #expect(session.setBudget(seconds: 90) == false)
    session.endMeeting(at: 90)
    session.start(at: 100)
    #expect(session.phase == .summary)
    #expect(session.setBudget(seconds: 90) == false)
}

@Test func budgetValidationPreservesPreviousValue() {
    var session = TimerSession()
    for invalid in [-1, 0, 9, 10, 14, 3601, Int.max] {
        #expect(session.setBudget(seconds: invalid) == false)
        #expect(session.budgetSeconds == 60)
    }
    #expect(session.setBudget(seconds: 15) == true)
    #expect(session.setBudget(seconds: 3600) == true)
    #expect(TimerSession(budgetSeconds: -1).budgetSeconds == 60)
}

@Test func deadlineEventOccursOncePerTurnEvenAfterPause() {
    var session = TimerSession(budgetSeconds: 15)
    session.start(at: 0)
    #expect(session.consumeDeadline(at: 14) == false)
    #expect(session.consumeDeadline(at: 15) == true)
    #expect(session.consumeDeadline(at: 16) == false)
    session.pause(at: 17)
    #expect(session.consumeDeadline(at: 100) == false)
    session.resume(at: 25)
    #expect(session.consumeDeadline(at: 26) == false)
    session.finish(at: 27)
    #expect(session.consumeDeadline(at: 42) == true)
}

@Test func countdownRoundsUpAndOvertimeIsExplicit() {
    var session = TimerSession(budgetSeconds: 15)
    session.start(at: 0)
    #expect(session.reading(at: 0.1).text == "00:15")
    #expect(session.reading(at: 14.9).text == "00:01")
    #expect(session.reading(at: 15).text == "00:00")
    #expect(session.reading(at: 15.1).text == "+00:01")
    #expect(session.reading(at: 75).text == "+01:00")
    #expect(session.phase == .running)
}
