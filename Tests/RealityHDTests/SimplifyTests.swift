import Testing
import simd
import Foundation
@testable import RealCore
@testable import RealLibrary

@Suite struct SimplifyTests {
    @Test func autoLevelsReduceFieldProps() {
        for (name, m) in [("fence", BostonIronFence().build(seed: 1)), ("lamp", BostonAcornLamp().build(seed: 1)),
                          ("bench", ParkBench().build(seed: 1))] {
            let t0 = Date()
            let a = m.withAutoLevels()
            let ms = Date().timeIntervalSince(t0) * 1000
            print("simplify", name, a.levels.map(\.triangleCount), a.switchDistances, Int(ms), "ms")
            #expect(ms < 2000)
            for l in a.levels.dropFirst() { #expect(l.triangleCount < m.levels[0].triangleCount) }
        }
    }
}
