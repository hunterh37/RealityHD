import simd
import Foundation

/// Shared builders for details group 16: pressed mud tracks, flat shed ribbons, bone bits.
enum DetailKit16 {
    static func rot(_ d: V2, _ a: Float) -> V2 { V2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a)) }

    /// Oval stamp: returns (imprint weight, wide berm weight) at q.
    static func stamp(_ q: V2, c: V2, dir: V2, len: Float, wid: Float, berm: Float = 1.6) -> (Float, Float) {
        let w = DetailKit06.oval(q, c: c, dir: dir, len: len, wid: wid)
        let wb = DetailKit06.oval(q, c: c, dir: dir, len: len * berm, wid: wid * berm)
        return (w, wb * (1 - w))
    }

    /// Mud disc with pressed impressions. `press(q)` returns (depth weight 0...1, berm weight 0...1).
    static func mudDisc(seed: UInt64, radius: Float, rings: Int, sectors: Int, depth: Float, press: (V2) -> (Float, Float)) -> Surface {
        var rng = SeededRNG(seed: seed &+ 77)
        let ph = rng.float(0...50)
        return GroundMesh.disc(material: "ground.mud", rings: rings, sectors: sectors,
            outline: { a in GroundMesh.outline(a, radius: radius, wobble: 0.1, seed: UInt32(seed & 0xFFFF)) },
            height: { q, t in
                let noise = 0.002 * Noise.fbm(V3(q.x * 14 + ph, 0, q.y * 14), octaves: 3, seed: 21)
                let (dep, berm) = press(q)
                return (0.02 + noise - depth * dep + 0.0035 * berm) * GroundMesh.rim(t, from: 0.72)
            })
    }

    /// Flattened wobbly ribbon tube along `path`; `half` is the half width per point, `thick` the half
    /// height. `roll` twists the section per point. Open at both ends, closes at zero width.
    static func ribbon(path: [V3], half: [Float], thick: Float, roll: [Float], noise: Float, rng: inout SeededRNG, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let sides = 8, n = path.count
        var dist: Float = 0
        for i in 0..<n {
            if i > 0 { dist += simd_length(path[i] - path[i - 1]) }
            let t = simd_normalize(path[min(i + 1, n - 1)] - path[max(i - 1, 0)])
            var side = simd_cross(V3(0, 1, 0), t)
            side = simd_normalize(side)
            let up = simd_cross(t, side)
            for k in 0..<sides {
                let a = Float(k) / Float(sides) * 2 * .pi + roll[i]
                let wob = 1 + noise * (rng.float() - 0.5) * 2
                let off = side * (cos(a) * half[i] * wob) + up * (sin(a) * thick * (half[i] / max(half[0], 0.0001)) * wob)
                let nrm = simd_normalize(side * cos(a) + up * sin(a) * 3)
                s.add(path[i] + off, nrm, V2(Float(k) / Float(sides) * 0.05, dist))
            }
        }
        for i in 0..<(n - 1) {
            for k in 0..<sides {
                let a = UInt32(i * sides + k), b = UInt32(i * sides + (k + 1) % sides)
                s.quad(a, b, UInt32((i + 1) * sides + (k + 1) % sides), UInt32((i + 1) * sides + k))
            }
        }
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    /// Small bone splinter: thin tapered rod with a flared knob at one end.
    static func bone(from a: V3, to b: V3, r: Float, rng: inout SeededRNG, material: MaterialKey) -> Surface {
        let mid = (a + b) / 2 + V3(rng.float(-0.0008...0.0008), rng.float(-0.0005...0.0005), rng.float(-0.0008...0.0008))
        let pts = [a, (a + mid) / 2, mid, (mid + b) / 2, b]
        let radii: [Float] = [r * 1.7, r * 1.0, r * 0.8, r * 0.85, r * 0.5].map { $0 * rng.float(0.9...1.1) }
        return Prim.tube(pts, radii: radii, sides: 5, seamTile: 0.02, material: material, capEnd: true)
    }
}
