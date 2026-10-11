import Testing
@testable import RealCore
@testable import RealLibrary

/// Size-parameter variants used by flight courses (VisionSpacecraft specs 04, 15) stay in budget.
@Suite struct AerospaceParamTests {
    @Test func tallPylonIsLatticeInBudget() {
        var p = Pylon(); p.radius = 1.5; p.height = 150
        let m = p.build(seed: 1).levels[0]
        #expect(m.triangleCount <= Pylon.budget)
        #expect(m.bounds.max.y > 149)
    }
}

@Suite struct AerospaceCourseSizeTests {
    @Test func courseWallsStayInBudget() {
        for (w, h, t, slot) in [(Float(200), Float(100), Float(2), Float(18)), (240, 250, 3, 0)] {
            var g = GapWall(); g.width = w; g.height = h; g.thickness = t; g.slotWidth = slot; g.slotCenter = 25
            let m = g.build(seed: 1).levels[0]
            #expect(m.triangleCount <= GapWall.budget)
            #expect(abs((m.bounds.max.x - m.bounds.min.x) - w) < 0.5)
        }
    }
}
