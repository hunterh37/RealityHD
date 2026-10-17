import Testing
import simd
import Foundation
@testable import RealCore
@testable import RealLibrary

@Suite struct SimplifyTests {
    @Test func autoLevelsReduceFieldProps() {
        for (name, m) in [("fence", BostonIronFence().build(seed: 1)), ("lamp", BostonAcornLamp().build(seed: 1)),
                          ("bench", ParkBench().build(seed: 1))] {
            let saved = SimplifyDiskCache.directory, wasOn = SimplifyDiskCache.isEnabled
            SimplifyDiskCache.directory = FileManager.default.temporaryDirectory.appendingPathComponent("rflod-\(UUID().uuidString)")
            SimplifyDiskCache.isEnabled = true
            defer { try? FileManager.default.removeItem(at: SimplifyDiskCache.directory); SimplifyDiskCache.directory = saved; SimplifyDiskCache.isEnabled = wasOn }
            let t0 = Date()
            let a = m.withAutoLevels(cacheID: name, seed: 1)
            let cold = Date().timeIntervalSince(t0) * 1000
            #if !DEBUG
            #expect(cold < 2000)   // debug builds simplify 10-40x slower; the cache covers them below
            #endif
            // Cold run stores asynchronously; wait for the file, then the warm run must skip simplification.
            let deadline = Date().addingTimeInterval(10)
            while ((try? FileManager.default.contentsOfDirectory(atPath: SimplifyDiskCache.directory.path))?.isEmpty ?? true), Date() < deadline {
                Thread.sleep(forTimeInterval: 0.05)
            }
            let t1 = Date()
            let w = m.withAutoLevels(cacheID: name, seed: 1)
            let ms = Date().timeIntervalSince(t1) * 1000
            print("simplify", name, a.levels.map(\.triangleCount), a.switchDistances, "cold", Int(cold), "ms warm", Int(ms), "ms")
            #expect(ms < 2000)
            #expect(w.levels.map(\.triangleCount) == a.levels.map(\.triangleCount))
            #expect(w.switchDistances == a.switchDistances)
            #expect(w.levels[1].surfaces.map(\.positions) == a.levels[1].surfaces.map(\.positions))
            for l in a.levels.dropFirst() { #expect(l.triangleCount < m.levels[0].triangleCount) }
        }
    }
}
