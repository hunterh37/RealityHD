import simd
import Foundation

/// Shared builders for details group 02: curled sheets, flat chips, jittered limbs, lumps.
enum DetailKit02 {
    /// Curled two-sided sheet lying on the ground, `len` along X, `wid` along Z, thickness `t`.
    /// `curl` bends it across the width, `bow` along the length; ragged ends use `rag` (fraction of len).
    static func sheet(len: Float, wid: Float, t: Float, curl: Float, bow: Float, rag: Float, rise: Float,
                      rng: inout SeededRNG, top: MaterialKey, under: MaterialKey) -> [Surface] {
        let nx = 7, nz = 5
        var rowsT: [[V3]] = [], rowsB: [[V3]] = [], uv: [[V2]] = []
        let ends = (0...nz).map { _ in rng.float(0...rag) * len }
        let ends2 = (0...nz).map { _ in rng.float(0...rag) * len }
        let wob = (0...nx).map { _ in rng.float(-0.06...0.06) * wid }
        for i in 0...nx {
            var rt: [V3] = [], rb: [V3] = [], ru: [V2] = []
            let f = Float(i) / Float(nx)
            for k in 0...nz {
                let g = Float(k) / Float(nz)
                let x0 = -len / 2 + ends[k], x1 = len / 2 - ends2[k]
                let x = x0 + (x1 - x0) * f
                let a = (g - 0.5) * curl
                let w = wid / 2 * (0.9 + 0.1 * sin(f * .pi)) // narrower at the ends
                let z = sin(a) / max(curl, 0.01) * 2 * w * 0.5 * (curl > 0.01 ? curl : 1) + wob[i] * (g - 0.5)
                let zz = (g - 0.5) * 2 * w * cos(a * 0.6)
                _ = z
                let y = rise + (1 - cos(a)) * wid * 0.35 + sin(f * .pi) * bow + Float(i % 2) * 0.0005
                let p = V3(x, y, zz + wob[i])
                rt.append(p + V3(0, t / 2, 0)); rb.append(p - V3(0, t / 2, 0))
                ru.append(V2(f * len * 3, g * wid * 3))
            }
            rowsT.append(rt); rowsB.append(rb); uv.append(ru)
        }
        var a = WoodParts.grid(rowsT, uvs: uv, material: top)
        var b = WoodParts.grid(rowsB.reversed(), uvs: uv.reversed(), material: under)
        a.recomputeNormals(weldSeams: false); b.recomputeNormals(weldSeams: false)
        return [a, b]
    }

    /// Flat splinter/chip: pointed at both ends, `len` x `wid` x `t`, centered at `at`, yawed and tilted.
    static func chip(len: Float, wid: Float, t: Float, at: V3, yaw: Float, tilt: V2, material: MaterialKey) -> Surface {
        let path: [V3] = [V3(-0.5, 0, 0), V3(-0.3, 0, 0), V3(0.05, 0, 0), V3(0.35, 0, 0), V3(0.5, 0, 0)]
        let r: [Float] = [0.04, 0.4, 0.5, 0.3, 0.03]
        var s = Prim.tube(path, radii: r, sides: 4, seamTile: 0.2, material: material, capEnd: true)
        let q = simd_quatf(angle: yaw, axis: V3(0, 1, 0)) * simd_quatf(angle: tilt.x, axis: V3(1, 0, 0)) * simd_quatf(angle: tilt.y, axis: V3(0, 0, 1))
        s = s.transformed(Xform(translation: at, rotation: q, scale: V3(len, t / 0.5 * 0.5 / 0.5 * 0.5 + t, wid * 2)))
        s.recomputeNormals(weldSeams: false)
        return s
    }

    /// Lumpy flattened blob (fungus spot, crust) on a surface point.
    static func lump(at: V3, normal: V3, radius: Float, height: Float, rng: inout SeededRNG, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let n = normal.normalized
        let e1 = n.anyPerpendicular.normalized, e2 = simd_cross(n, e1)
        let c = s.add(at + n * height, n, V2(0.5, 0.5))
        let seg = 8
        var ring: [UInt32] = []
        for i in 0..<seg {
            let a = Float(i) / Float(seg) * 2 * .pi
            let rr = radius * rng.float(0.65...1.2)
            let p = at + (e1 * cos(a) + e2 * sin(a)) * rr + n * (-0.0005)
            ring.append(s.add(p, n, V2(0.5 + cos(a) * 0.5, 0.5 + sin(a) * 0.5)))
        }
        let c2 = s.add(at + n * height, -n, V2(0.5, 0.5))
        var ring2: [UInt32] = []
        for i in 0..<seg { ring2.append(s.add(s.positions[Int(ring[i])], -n, s.uvs[Int(ring[i])])) }
        for i in 0..<seg { s.tri(c, ring[i], ring[(i + 1) % seg]); s.tri(c2, ring2[(i + 1) % seg], ring2[i]) }
        return s
    }

    /// Wobbly limb path from `a` along `d`.
    static func limbPath(from a: V3, dir: V3, len: Float, segs: Int, wobble: Float, rng: inout SeededRNG) -> [V3] {
        var pts = [a], p = a, d = dir.normalized
        for _ in 0..<segs {
            d = simd_normalize(d + V3(rng.float(-wobble...wobble), rng.float(-wobble...wobble) * 0.5, rng.float(-wobble...wobble)))
            p += d * len / Float(segs)
            pts.append(p)
        }
        return pts
    }
}
