import simd
import Foundation

/// Shared helpers for details group 19.
enum DetailKit19 {
    /// Lumpy superellipsoid stone with flattened top and bottom, in local space, then rotated and moved.
    static func stone(_ size: V3, at c: V3, yaw: Float, tilt: V3, n: Int, squareness: Float = 3, lump: Float = 0.08,
                      flat: Float = 0.75, material: MaterialKey, rng: inout SeededRNG) -> Surface {
        let ph = (0..<6).map { _ in rng.float(0...6.28) }
        let h = size * 0.5
        let raw = Prim.cubeSphere(subdivisions: n, material: material) { d in
            let r = pow(pow(abs(d.x), squareness) + pow(abs(d.y), squareness) + pow(abs(d.z), squareness), -1 / squareness)
            let l = 1 + lump * (sin(d.x * 3.1 + ph[0]) * sin(d.y * 2.7 + ph[1]) + sin(d.z * 3.7 + ph[2]) * sin(d.x * 2.3 + ph[3])
                + 0.5 * sin(d.y * 6.1 + d.z * 4.3 + ph[4]) * sin(d.x * 5.2 + ph[5]))
            var p = V3(d.x * r * h.x, d.y * r * h.y, d.z * r * h.z) * l
            p.y = max(-h.y * flat, min(h.y * flat, p.y)) + 0.002 * sin(p.x * 90 + ph[0]) * sin(p.z * 70 + ph[1])
            return p
        }
        let q = simd_quatf(angle: yaw, axis: V3(0, 1, 0)) * simd_quatf(angle: tilt.x, axis: V3(1, 0, 0)) * simd_quatf(angle: tilt.z, axis: V3(0, 0, 1))
        var s = Surface(material: material)
        s.append(raw, Xform(translation: c, rotation: q))
        return s
    }

    /// Low irregular mound of soil or litter around a base, ground-hugging.
    static func mound(radius: Float, height: Float, at c: V3, material: MaterialKey, rng: inout SeededRNG) -> Surface {
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        let raw = Prim.cubeSphere(subdivisions: 6, material: material) { d in
            let l = 1 + 0.18 * sin(d.x * 4 + ph[0]) * sin(d.z * 3.4 + ph[1]) + 0.08 * sin(d.x * 9 + d.z * 7 + ph[2])
            return V3(d.x * radius * l, max(d.y, -0.1) * height * (d.y > 0 ? 1 : 0.2), d.z * radius * l * 0.85)
        }
        var s = Surface(material: material)
        s.append(raw, Xform(translation: c, rotation: simd_quatf(angle: rng.float(0...6.28), axis: V3(0, 1, 0))))
        return s
    }

    /// Wobbly closed-ish loop path used for line tangles.
    static func loopPath(center: V3, radius: V3, turns: Float, segs: Int, phase: Float, rng: inout SeededRNG) -> [V3] {
        let w = (0..<4).map { _ in rng.float(0...6.28) }
        return (0...segs).map { i in
            let t = Float(i) / Float(segs), a = phase + t * turns * 2 * .pi
            let k = 1 + 0.35 * sin(a * 1.7 + w[0]) + 0.2 * sin(a * 3.1 + w[1])
            let y = 0.5 + 0.5 * sin(a * 0.8 + w[2]) * sin(a * 1.3 + w[3])
            return center + V3(cos(a) * radius.x * k, 0.001 + y * radius.y, sin(a) * radius.z * k * (0.8 + 0.2 * sin(a * 2.3 + w[0])))
        }
    }

    /// Sweep a superellipse cross-section (w across, t thick) along a planar path in XZ (radial = across, Y = thick).
    static func flatBar(path: [V2], width: [Float], thick: [Float], y0: Float, sides: Int = 10, rough: Float, material: MaterialKey,
                        rng: inout SeededRNG) -> Surface {
        var s = Surface(material: material)
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        var v: Float = 0
        for (i, p) in path.enumerated() {
            let a = path[max(0, i - 1)], b = path[min(path.count - 1, i + 1)]
            let tg = simd_normalize(b - a)
            let nrm = V2(-tg.y, tg.x)
            if i > 0 { v += simd_distance(p, path[i - 1]) }
            for k in 0...sides {
                let u = Float(k) / Float(sides), ang = u * 2 * .pi
                let c = cos(ang), sn = sin(ang)
                let e = pow(pow(abs(c), 4) + pow(abs(sn), 4), -0.25)
                let pit = 1 + rough * sin(Float(i) * 2.9 + ph[0] + ang * 3) * sin(Float(i) * 1.7 + ph[1]) + rough * 0.6 * sin(ang * 7 + Float(i) * 5.3 + ph[2])
                let across = c * e * width[i] * 0.5 * pit, up = sn * e * thick[i] * 0.5 * pit
                let pos = V3(p.x + nrm.x * across, y0 + thick[i] * 0.5 + up, p.y + nrm.y * across)
                let dir = simd_normalize(V3(nrm.x * c, sn, nrm.y * c))
                s.add(pos, dir, V2(u * (width[i] + thick[i]) * 2, v))
            }
        }
        let row = UInt32(sides + 1)
        for i in 0..<(path.count - 1) { for k in 0..<sides {
            let a = UInt32(i) * row + UInt32(k)
            s.quad(a, a + 1, a + row + 1, a + row)
        }}
        for end in [0, path.count - 1] {
            let base = UInt32(end) * row
            let ctr = V3(path[end].x, y0 + thick[end] * 0.5, path[end].y)
            let ci = s.add(ctr, end == 0 ? V3(0, 0, 0) : V3(0, 0, 0), V2(0, 0))
            for k in 0..<UInt32(sides) { if end == 0 { s.tri(base + k + 1, base + k, ci) } else { s.tri(base + k, base + k + 1, ci) } }
        }
        s.recomputeNormals(); s.computeTangents()
        return s
    }
}
