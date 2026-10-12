import Testing
@testable import RealLibrary
import RealCore

@Suite struct SiphonBarTests {
    @Test func startsOffAndDark() {
        let b = SiphonBurner()
        #expect(b.mode == .off)
        #expect(b.lampLevel == 0)
        #expect(b.display == "----")
        #expect(b.segmentMasks == [0b1000000, 0b1000000, 0b1000000, 0b1000000])
    }

    @Test func outputSetClampsAndShows() {
        var b = SiphonBurner()
        b.press(.out)
        for _ in 0..<12 { b.press(.up) }
        #expect(b.output == 10)
        #expect(b.display == "P 10")
        for _ in 0..<15 { b.press(.down) }
        #expect(b.output == 1)
        #expect(b.display == "P  1")
        b.tick(5)
        #expect(b.setting == .none)
    }

    @Test func timeSetStepsByFiveSeconds() {
        var b = SiphonBurner()
        b.press(.time)
        b.press(.up); b.press(.up)
        #expect(b.brewTime == 70)
        #expect(b.display == "0110")
        for _ in 0..<40 { b.press(.down) }
        #expect(b.brewTime == SiphonBurner.timeRange.lowerBound)
    }

    @Test func heatRampsToBoil() {
        var b = SiphonBurner()
        b.press(.heat)
        #expect(b.lampLevel == 1)
        var t = 0.0
        while !b.boiling && t < 600 { b.tick(1); t += 1 }
        #expect(b.boiling)
        #expect(t > 90 && t < 360, "boil after \(t) s")
        #expect(b.display.hasSuffix("C"))
    }

    @Test func extractCountsDownThenStops() {
        var b = SiphonBurner()
        b.press(.out); b.press(.down); b.press(.down)   // 6 -> 4
        b.press(.brew)
        #expect(b.mode == .extracting)
        #expect(b.activeOutput == 4)
        #expect(b.display == "0100")
        b.tick(15.2)
        #expect(b.display == "0045")
        b.tick(50)
        #expect(b.mode == .off)
        #expect(b.lampLevel == 0)
        #expect(b.finished)
    }

    @Test func timerStartPausesAndResumes() {
        var b = SiphonBurner()
        b.press(.timer)
        b.tick(10)
        b.press(.timer)
        #expect(!b.timerRunning)
        #expect(b.remaining == 50)
        b.tick(10)
        #expect(b.remaining == 50)
        b.press(.timer)
        b.tick(50)
        #expect(b.remaining == 0)
        #expect(b.mode == .off)
    }

    @Test func keepWarmAndStop() {
        var b = SiphonBurner()
        b.press(.warm)
        #expect(b.activeOutput == SiphonBurner.keepWarmOutput)
        #expect(b.display == "L  2")
        b.press(.stop)
        #expect(b.mode == .off)
        #expect(b.lampLevel == 0)
    }

    @Test func controllerRoutesPartNames() {
        var c = SiphonBarController()
        let a = c.press(part: "right-heat"), b = c.press(part: "right-seg0-1"), m = c.press(part: "middle-heat")
        #expect(a && !b && !m)
        #expect(c.right.mode == .heating)
        #expect(c.left.mode == .off)
    }

    @Test func rigHasEveryKeyAndSegment() {
        let rig = HalogenSiphonBar().rig(seed: 1)
        for side in ["left", "right"] {
            for k in SiphonBurner.Key.allCases { #expect(rig.index("\(side)-\(k.rawValue)") != nil) }
            for d in 0..<4 { for b in 0..<7 { #expect(rig.index(HalogenSiphonBar.segmentPart(side, digit: d, bit: b)) != nil) } }
        }
        #expect(rig.validate().isEmpty)
    }
}
