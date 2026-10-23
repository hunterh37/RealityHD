import simd
import Foundation

/// Shared helpers for details group 04 (fungi, moss, lichen).
enum DetailKit04 {
    /// Flip triangles so normals face away from `center(p)`, then rebuild normals and tangents.
    static func orient(_ s: inout Surface, center: (V3) -> V3) {
        WoodParts.orientOutward(&s, center: center)
        s.recomputeNormals(); s.computeTangents()
    }
    static func orient(_ s: inout Surface, toward d: V3) { orient(&s, center: { $0 - d }) }

    static func noise(_ x: Float, _ z: Float, _ freq: Float, _ seed: UInt32) -> Float {
        Noise.perlin(V3(x * freq, 0.37, z * freq), seed: seed)
    }

    /// Irregular organic outline radius factor around angle `a`.
    static func outline(_ a: Float, lobes: Float, phases: V3, k: Int = 5) -> Float {
        let o = 0.5 * sin(2 * a + phases.x) + 0.3 * sin(3 * a + phases.y) + 0.2 * sin(Float(k) * a + phases.z)
        return max(0.45, 1 + lobes * o)
    }

    /// Upward-facing irregular patch centered at `c`. `height(x, z, t)` gives y, t = 0 center ... 1 edge.
    static func patch(at c: V2, radius: Float, rings: Int, sectors: Int, rng: inout SeededRNG, lobes: Float,
                      lobeCount: Int = 5, material: MaterialKey, height: (Float, Float, Float) -> Float) -> Surface {
        let ph = V3(rng.float(0...6.28), rng.float(0...6.28), rng.float(0...6.28))
        var rows: [[V3]] = [], uvs: [[V2]] = []
        for i in 0...rings {
            let t = Float(i) / Float(rings)
            var row: [V3] = [], uv: [V2] = []
            for k in 0...sectors {
                let a = Float(k % sectors) / Float(sectors) * 2 * .pi
                let r = radius * t * outline(a, lobes: lobes, phases: ph, k: lobeCount)
                let x = c.x + r * cos(a), z = c.y + r * sin(a)
                row.append(V3(x, height(x, z, t), z)); uv.append(V2(x, z))
            }
            rows.append(row); uvs.append(uv)
        }
        var s = WoodParts.grid(rows, uvs: uvs, material: material)
        orient(&s, toward: .up)
        return s
    }

    /// Splits `m` into LOD-specific copies: build(lod) is called for 0 and 1.
    static func lods(_ f: (Int) -> Model) -> LODModel {
        LODModel(levels: [f(0), f(1)], switchDistances: [3])
    }
}
