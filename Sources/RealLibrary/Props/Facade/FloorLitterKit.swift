import simd
import Foundation

/// Helpers for the 2 x 2 m dirt, track and forest-floor tiles: half-buried stones, fallen leaves,
/// pine needles, twigs and cones. Tiles are centered, base at y = 0, built on `GK.field`.
enum FLK {
    /// Height of a `GK.field` surface at `p` (same fall-off as the field).
    static func height(_ p: V2, w: Float, d: Float, edge: Float, bump: (V2) -> Float) -> Float {
        let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y)), k = max(0, min(1, e / 0.06))
        return edge + bump(p) * k * k * (3 - 2 * k)
    }

    /// Field stone: noisy flattened superellipsoid at `p`, random yaw and tilt.
    static func stone(_ m: inout Model, at p: V3, size: Float, flat: ClosedRange<Float> = 0.45...0.7, _ mat: MaterialKey, rng: inout SeededRNG) {
        let sd = UInt32(rng.int(0...9999))
        let s = Prim.superellipsoid(V3(size, size * rng.float(flat), size * rng.float(0.6...0.9)), exponent: rng.float(2.2...3.2),
                                    subdivisions: size > 0.06 ? 3 : 2, material: mat) { d in
            1 + 0.18 * Noise.fbm(d * 2.2, octaves: 2, seed: sd)
        }
        m.add(s, Xform(translation: p, rotation: simd_quatf(degrees: rng.float(0...360), axis: .up) * simd_quatf(degrees: rng.float(-12...12), axis: V3(1, 0, 0))))
    }

    /// Fallen leaf lying on the ground at `p`: a cutout leaf card (`width` x `length`, UVs 0...1 with
    /// v along the blade) curled up at the margins and the tip, tilted a little off the ground.
    static func leaf(at p: V3, length: Float, width: Float, yaw: Float, curl: Float, rng: inout SeededRNG, material: MaterialKey) -> Surface {
        var s = Prim.terrain(size: V2(width, length), segments: 2, material: material) { _ in 0 }
        let tilt = rng.float(-0.15...0.15), roll = rng.float(-0.1...0.1)
        s.positions = s.positions.map { q in
            let u = q.x / (width / 2), v = q.z / (length / 2)
            let y = curl * width * 0.14 * u * u + 0.05 * length * max(0, v) * max(0, v) + tilt * q.z + roll * q.x
            return V3(q.x, y, q.z)
        }
        s.uvs = s.positions.map { V2($0.x / width + 0.5, $0.z / length + 0.5) }
        s.recomputeNormals(weldSeams: true); s.computeTangents()
        return s.transformed(Xform(translation: p, rotation: simd_quatf(angle: yaw, axis: .up)))
    }

    /// Bundle of `count` pine needles (fascicle) lying near `p`, mostly flat, crossing each other.
    static func needles(at p: V3, count: Int, length: Float, yaw: Float, rng: inout SeededRNG, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        for _ in 0..<count {
            let a = yaw + rng.float(-0.35...0.35)
            let dir = V3(cos(a), 0, sin(a))
            let side = V3(-dir.z, 0, dir.x) * rng.float(-0.006...0.006)
            let l = length * rng.float(0.75...1.05)
            let p0 = p + side + V3(0, rng.float(0.0005...0.004), 0)
            let mid = p0 + dir * l * 0.5 + V3(0, rng.float(0.0...0.006), 0) + side * 0.6
            s.append(Prim.tube([p0, mid, p0 + dir * l + V3(0, rng.float(-0.002...0.004), 0)], radii: [0.0008, 0.0007, 0.0003],
                               sides: 3, seamTile: 0.1, material: material, capEnd: false))
        }
        return s
    }

    /// Fallen twig: kinked tube with one side branch, lying on the ground at `p`.
    static func twig(at p: V3, length: Float, radius: Float, yaw: Float, rng: inout SeededRNG, material: MaterialKey) -> Surface {
        let dir = V3(cos(yaw), 0, sin(yaw)), side = V3(-dir.z, 0, dir.x)
        var pts: [V3] = [], radii: [Float] = []
        for i in 0...4 {
            let t = Float(i) / 4
            pts.append(p + dir * length * t + side * rng.float(-0.015...0.015) * length + V3(0, radius + 0.002 * sin(t * 3), 0))
            radii.append(radius * (1 - 0.55 * t))
        }
        var s = Prim.tube(pts, radii: radii, sides: 6, seamTile: 0.15, material: material, capEnd: true)
        let b0 = pts[2], bd = simd_normalize(dir + side * rng.float(0.6...1.0) * (rng.chance(0.5) ? 1 : -1))
        s.append(Prim.tube([b0, b0 + bd * length * 0.3 + V3(0, 0.004, 0)], radii: [radius * 0.5, radius * 0.25],
                           sides: 5, seamTile: 0.15, material: material, capEnd: true))
        return s
    }

    /// Pine cone lying on its side: tapered core with spiralled scales.
    static func cone(_ m: inout Model, at p: V3, length: Float, yaw: Float, open: Float, rng: inout SeededRNG, scale: MaterialKey) {
        let r = simd_quatf(angle: yaw, axis: .up)
        let rad = length * 0.32
        m.add(Prim.superellipsoid(V3(length * 0.92, rad * 1.1, rad * 1.1), exponent: 2, subdivisions: 2, material: scale),
              Xform(translation: p + V3(0, rad * 0.95, 0), rotation: r))
        let n = 34
        for i in 0..<n {
            let t = Float(i) / Float(n - 1)
            let x = (t - 0.5) * length * 0.9
            let env = sin(Float.pi * (0.12 + 0.82 * t)) * (t < 0.3 ? 0.85 : 1)
            let a = Float(i) * 2.399
            let o = V3(x, cos(a) * rad * env, sin(a) * rad * env)
            let sz = length * 0.13 * (0.5 + 0.6 * env)
            let q = r * simd_quatf(angle: a, axis: V3(1, 0, 0)) * simd_quatf(angle: -open * 0.9 - 0.2, axis: V3(0, 0, 1))
            m.add(Prim.superellipsoid(V3(sz * 0.9, sz * 0.32, sz), exponent: 2.6, subdivisions: 1, material: scale),
                  Xform(translation: p + V3(0, rad * 0.95, 0) + r.act(o), rotation: q))
        }
    }
}
