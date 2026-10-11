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
