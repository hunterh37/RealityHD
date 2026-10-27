import Testing
import simd
@testable import RealCore
@testable import RealLibrary

/// DD1H tableware props: winding agrees with vertex normals on every surface.
@Suite struct DD1HTablewareTests {
    static let assets: [any RealAsset.Type] = [CutleryTray.self, ClothNapkinRing.self, Placemat.self, CoasterSet.self, Trivet.self]

    @Test func windingMatchesNormals() {
        for a in Self.assets {
            let m = a.init().build(seed: 1).levels[0]
            for s in m.surfaces where !s.isEmpty {
                var bad = 0, total = 0
                for t in stride(from: 0, to: s.indices.count, by: 3) {
                    let i = Int(s.indices[t]), j = Int(s.indices[t + 1]), k = Int(s.indices[t + 2])
                    let n = simd_cross(s.positions[j] - s.positions[i], s.positions[k] - s.positions[i])
                    if simd_length(n) < 1e-12 { continue }
                    total += 1
                    if simd_dot(n, s.normals[i] + s.normals[j] + s.normals[k]) < 0 { bad += 1 }
                }
                #expect(Double(bad) <= Double(total) * 0.06 + 2, "\(a.id) \(s.material): \(bad)/\(total) triangles wound against their normals")
            }
        }
    }
}
