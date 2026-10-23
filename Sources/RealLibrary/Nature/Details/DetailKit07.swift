import simd
import Foundation

/// Shared builders for details group 07 (feathers, nests, shells, snails, antler).
enum DetailKit07 {
    static let leafMat: MaterialKey = "litter.dry:C09860"

    static func lods(seed: UInt64, switchAt: Float = 3, _ f: (Int, inout SeededRNG) -> Model) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let st = rng.state
        let m0 = f(0, &rng)
        var r2 = SeededRNG(seed: 1); r2.state = st
        let m1 = f(1, &r2)
        return LODModel(levels: [m0, m1], switchDistances: [switchAt])
    }

    static func finish(_ name: String, _ surfs: [Surface]) -> Model {
        var m = Model(name: name)
        for var s in surfs where !s.positions.isEmpty { s.computeTangents(); m.add(s) }
        groundAO(&m)
        return m
    }

    static func xf(_ s: Surface, _ x: Xform) -> Surface {
        var o = Surface(material: s.material); o.append(s, x); return o
    }

    /// Lowest point of the group goes to -sink; optionally centers the bounding box on X/Z.
    static func settle(_ ss: inout [Surface], sink: Float, center: Bool) {
        var lo = V3(repeating: .infinity), hi = V3(repeating: -.infinity)
        for s in ss { for p in s.positions { lo = simd_min(lo, p); hi = simd_max(hi, p) } }
        let d = V3(center ? -(lo.x + hi.x) / 2 : 0, -lo.y - sink, center ? -(lo.z + hi.z) / 2 : 0)
        for i in ss.indices { for j in ss[i].positions.indices { ss[i].positions[j] += d } }
    }

    static func rotated(_ ss: [Surface], _ q: simd_quatf) -> [Surface] {
        ss.map { xf($0, Xform(translation: .zero, rotation: q)) }
    }

    static func shift(_ ss: inout [Surface], _ t: V3) {
        for i in ss.indices { for j in ss[i].positions.indices { ss[i].positions[j] += t } }
    }

    static func yaw(_ a: Float) -> simd_quatf { simd_quatf(angle: a, axis: V3(0, 1, 0)) }

    /// Ellipsoid blob with per-direction jitter.
    static func blob(_ r: V3, sub: Int, material: MaterialKey, rng: inout SeededRNG, jitter: Float = 0.12) -> Surface {
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        return Prim.cubeSphere(subdivisions: sub, material: material) { d in
            let j = 1 + jitter * sin(d.x * 3.1 + ph[0]) * cos(d.y * 2.7 + ph[1]) + jitter * 0.6 * sin(d.z * 4.3 + ph[2])
            return V3(d.x * r.x, d.y * r.y, d.z * r.z) * j
        }
    }

    /// Cap of a thin spherical shell (outer, inner) with a jagged rim, pole at +Y.
    static func shard(radius R: Float, rim: Float, thickness: Float = 0.0004, outer: MaterialKey, inner: MaterialKey,
                      rng: inout SeededRNG, sides: Int = 10, rings: Int = 3) -> [Surface] {
        var rimA: [Float] = []
        for _ in 0..<sides { rimA.append(rim * rng.float(0.8...1.2)) }
        func build(_ rad: Float, flip: Bool, mat: MaterialKey) -> Surface {
            var s = Surface(material: mat)
            var idx: [[UInt32]] = []
            for j in 0...rings {
                var row: [UInt32] = []
                for i in 0..<sides {
                    let th = rimA[i] * Float(j) / Float(rings)
                    let ph = Float(i) / Float(sides) * 6.2832
                    let d = V3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
                    row.append(s.add(d * rad, flip ? -d : d, V2(Float(i) / Float(sides), Float(j) / Float(rings)) * 0.015))
                }
                idx.append(row)
            }
            for j in 0..<rings { for i in 0..<sides {
                let i2 = (i + 1) % sides
                if flip { s.quad(idx[j][i], idx[j + 1][i], idx[j + 1][i2], idx[j][i2]) }
                else { s.quad(idx[j][i], idx[j][i2], idx[j + 1][i2], idx[j + 1][i]) }
            } }
            return s
        }
        return [build(R, flip: false, mat: outer), build(R - thickness, flip: true, mat: inner)]
    }

    /// Garden snail shell, apex up, `size` = diameter in meters.
    static func snailShell(size: Float, material: MaterialKey, sides: Int, points: Int) -> Surface {
        let tmax: Float = 3.4 * .pi, b: Float = 0.3
        let rEnd = size * 0.22
        let r0 = rEnd / exp(b * tmax)
        var path: [V3] = [], radii: [Float] = []
        for i in 0..<points {
            let t = tmax * Float(i) / Float(points - 1)
            let rho = r0 * exp(b * t)
            let R = 0.95 * rho
            path.append(V3(cos(t) * R, -0.5 * rho, sin(t) * R))
            radii.append(max(rho, 0.0003))
        }
        return Prim.tube(path, radii: radii, sides: sides, seamTile: 0.05, material: material,
                         rippling: { a, c in 1 })
    }
}
