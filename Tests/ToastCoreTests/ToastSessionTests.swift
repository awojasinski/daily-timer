import Testing
import ToastArt
import Foundation
@testable import ToastCore

@Test(arguments: [
    (79.999, ToastOutcome.raw),
    (80.0, ToastOutcome.nailed),
    (100.0, ToastOutcome.nailed),
    (100.001, ToastOutcome.burnt)
])
func finishScoresExactThresholdAndImmediatelyStartsNext(elapsed: Double, expected: ToastOutcome) {
    var session = ToastSession(budgetSeconds: 100)
    session.start(at: 10)
    #expect(session.finish(at: 10 + elapsed) == expected)
    #expect(session.tally[expected] == 1)
    #expect(session.phase == .running)
    #expect(session.elapsed(at: 10 + elapsed) == 0)
    #expect(session.reading(at: 10 + elapsed).text == "01:40")
    #expect(session.elapsed(at: 11 + elapsed) == 1)
    #expect(session.setBudget(seconds: 60) == false)
}

@Test func deadlineEjectsOnceWithoutFinishingOrScoring() {
    var session = ToastSession(budgetSeconds: 15)
    session.start(at: 0)
    #expect(session.reading(at: 14).ejectionElapsed == nil)
    #expect(session.consumeDeadline(at: 15) == true)
    #expect(session.reading(at: 15).ejectionElapsed == 0)
    #expect(session.phase == .running)
    #expect(session.tally.isEmpty)
    #expect(session.consumeDeadline(at: 16) == false)
    #expect(session.reading(at: 16).ejectionElapsed == 1)
    #expect(session.finish(at: 17) == .burnt)
    #expect(session.reading(at: 17).ejectionElapsed == nil)
    #expect(session.consumeDeadline(at: 31) == false)
    #expect(session.consumeDeadline(at: 32) == true)
}

@Test func pauseExcludesTimeAndFinishFromPauseStartsNextRunning() {
    var session = ToastSession()
    session.start(at: 100)
    session.pause(at: 130)
    #expect(session.elapsed(at: 500) == 30)
    session.resume(at: 500)
    #expect(session.elapsed(at: 520) == 50)
    session.pause(at: 520)
    #expect(session.finish(at: 900) == .nailed)
    #expect(session.phase == .running)
    #expect(session.elapsed(at: 905) == 5)
}

@Test func endMeetingCountsLastPersonAndFreezesTotal() {
    var session = ToastSession()
    session.start(at: 0)
    #expect(session.finish(at: 20) == .raw)
    #expect(session.finish(at: 70) == .nailed)
    #expect(session.finish(at: 140) == .burnt)
    session.endMeeting(at: 145)
    #expect(session.phase == .summary)
    #expect(session.tally == [.raw: 2, .nailed: 1, .burnt: 1])
    #expect(session.elapsed(at: 200) == 5)
    #expect(session.totalSpeakingTime == 145)
    #expect(session.reading(at: 200).text == "02:25")
    session.endMeeting(at: 300)
    #expect(session.tally.values.reduce(0, +) == 4)
    #expect(session.finish(at: 300) == nil)
    #expect(session.consumeDeadline(at: 300) == false)
    session.start(at: 300)
    #expect(session.phase == .summary)
    #expect(session.setBudget(seconds: 90) == false)
}

@Test func endingPausedMeetingCountsSpeakerButExcludesPause() {
    var session = ToastSession()
    session.endMeeting(at: 0)
    #expect(session.phase == .idle)
    session.start(at: 0)
    session.pause(at: 40)
    session.endMeeting(at: 100)
    #expect(session.phase == .summary)
    #expect(session.tally == [.raw: 1])
    #expect(session.totalSpeakingTime == 40)
    #expect(session.reading(at: 200).text == "00:40")
    #expect(session.elapsed(at: 200) == 40)
}

@Test func newMeetingClearsSummaryAndKeepsBudget() {
    var session = ToastSession(budgetSeconds: 90)
    session.start(at: 0)
    _ = session.finish(at: 80)
    session.endMeeting(at: 85)
    session.resetMeeting()
    #expect(session.phase == .idle)
    #expect(session.tally.isEmpty)
    #expect(session.totalSpeakingTime == 0)
    #expect(session.reading(at: 100).text == "01:30")
    #expect(session.setBudget(seconds: 75) == true)
    session.start(at: 100)
    #expect(session.reading(at: 100).text == "01:15")
}

@Test func duplicateStartAndActiveBudgetChangesDoNotResetSpeaker() {
    var session = ToastSession()
    #expect(session.finish(at: 0) == nil)
    session.start(at: 10)
    session.start(at: 20)
    #expect(session.elapsed(at: 30) == 20)
    #expect(session.setBudget(seconds: 90) == false)
    session.pause(at: 30)
    #expect(session.setBudget(seconds: 90) == false)
    #expect(session.finish(at: 90) == .raw)
    #expect(session.reading(at: 90).text == "01:00")
}

@Test func budgetValidationPreservesPreviousValue() {
    var session = ToastSession()
    for invalid in [-1, 0, 9, 10, 14, 3601, Int.max] {
        #expect(session.setBudget(seconds: invalid) == false)
        #expect(session.budgetSeconds == 60)
    }
    #expect(session.setBudget(seconds: 15) == true)
    #expect(session.setBudget(seconds: 3600) == true)
    #expect(ToastSession(budgetSeconds: -1).budgetSeconds == 60)
}

@Test func resetDiscardsTurnAndScoresButPreservesBudget() {
    var session = ToastSession(budgetSeconds: 60)
    session.start(at: 0)
    _ = session.finish(at: 55)
    session.resetMeeting()
    #expect(session.phase == .idle)
    #expect(session.elapsed(at: 300) == 0)
    #expect(session.tally.values.reduce(0, +) == 0)
    #expect(session.budgetSeconds == 60)
}

@Test func deadlineEventOccursOncePerTurnEvenAfterPause() {
    var session = ToastSession(budgetSeconds: 15)
    session.start(at: 0)
    #expect(session.consumeDeadline(at: 14) == false)
    #expect(session.consumeDeadline(at: 15) == true)
    #expect(session.consumeDeadline(at: 16) == false)
    session.pause(at: 17)
    session.resume(at: 25)
    #expect(session.consumeDeadline(at: 26) == false)
    _ = session.finish(at: 27)
    #expect(session.consumeDeadline(at: 42) == true)
}

@Test func countdownRoundsUpAndOvertimeIsExplicit() {
    var session = ToastSession(budgetSeconds: 15)
    session.start(at: 0)
    #expect(session.reading(at: 0.1).text == "00:15")
    #expect(session.reading(at: 14.9).text == "00:01")
    #expect(session.reading(at: 15).text == "00:00")
    #expect(session.reading(at: 15.1).text == "+00:01")
    #expect(session.reading(at: 75).text == "+01:00")
    #expect(session.phase == .running)
}

@Test func defaultTurnRunsForOneMinute() {
    var session = ToastSession()
    session.start(at: 0)
    #expect(session.reading(at: 0).text == "01:00")
    #expect(session.reading(at: 48).outcome == .nailed)
    #expect(session.reading(at: 61).outcome == .burnt)
}

@Test func ejectionJumpsHighThenReboundsAndSettles() {
    #expect(ToastPop.offset(at: 0) == 20)
    #expect(ToastPop.offset(at: 0.32) < -65)
    #expect(abs(ToastPop.offset(at: 0.64)) < 0.001)
    #expect(ToastPop.offset(at: 0.72) > 0)
    #expect(ToastPop.offset(at: 0.92) < 0)
    #expect(ToastPop.offset(at: 2) == 0)
}

@Test func controlSurfaceStaysInsideVisibleToasterWithoutJumpSpace() {
    let controls = ToastGeometry.controls
    #expect(controls.minY > 180)
    #expect(controls.maxY < 263)
    #expect(controls.minX > 49)
    #expect(controls.maxX < 236)
    #expect(ToastGeometry.controlOffset.y > 23)
    #expect(controls.width < 180)
}

@Test func breadDragHandleFollowsVisibleLoafAndAvoidsEmptyJumpSpace() {
    for offset in [20.0, 0, ToastPop.offset(at: 0.32), ToastPop.offset(at: 0.72)] {
        let rect = ToastGeometry.breadDragRect(offset: offset)
        #expect(rect.height > 0)
        #expect(rect.minY >= 0)
        #expect(rect.maxY <= (ToastGeometry.petHeadroom + ToastGeometry.body.minY) * ToastGeometry.petScale)
        let loaf = ToastGeometry.bread(at: 4 + offset)
        for x in [rect.minX + 1, rect.maxX - 1] {
            for y in [rect.minY + 1, rect.maxY - 1] {
                #expect(loaf.contains(CGPoint(x: x / ToastGeometry.petScale,
                                             y: y / ToastGeometry.petScale - ToastGeometry.petHeadroom)))
            }
        }
    }
    #expect(ToastGeometry.breadDragRect(offset: -70).maxY < ToastGeometry.breadDragRect(offset: 0).minY)
}
