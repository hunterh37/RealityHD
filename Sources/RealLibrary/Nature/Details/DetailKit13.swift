import simd
import Foundation

/// Shared helpers for details group 13: irregular lathes, bracket-fungus fans, logs and frames.
enum DetailKit13 {
    /// Periodic sum of sines over an angle, for wobbly outlines.
    struct Noise {
        var h: [Int], a: [Float], p: [Float]
        init(_ rng: inout SeededRNG, harmonics: [Int], amp: Float) {
            h = harmonics
            a = harmonics.map { _ in amp * rng.float(0.4...1) / Float(harmonics.count).squareRoot() }
            p = harmonics.map { _ in rng.float(0...6.28) }
        }
        func v(_ ang: Float) -> Float {
            var s: Float = 0
            for i in h.indices { s += a[i] * sin(Float(h[i]) * ang + p[i]) }
            return s
        }
    }

    /// Lathe with per-angle radius scale and vertical lift. Closures take (angle, profile radius).
    static func revolve(_ profile: [V2], segs: Int, material: MaterialKey,
                        wob: (Float, Float) -> Float = { _, _ in 1 }, lift: (Float, Float) -> Float = { _, _ in 0 }) -> Surface {
        var s = Surface(material: material)
        let maxR = profile.map(\.x).max() ?? 0.05, circ = 2 * Float.pi * maxR
        var vAcc: [Float] = [0]
        for i in 1..<profile.count { vAcc.append(vAcc[i - 1] + simd_distance(profile[i], profile[i - 1])) }
        for (i, pr) in profile.enumerated() {
            for k in 0...segs {
                let t = Float(k) / Float(segs), a = t * 2 * .pi
                let r = pr.x * wob(a, pr.x)
                _ = s.add(V3(r * cos(a), pr.y + lift(a, pr.x), -r * sin(a)), .up, V2(t * circ, vAcc[i]))
            }
        }
        let row = UInt32(segs + 1)
        for i in 0..<(profile.count - 1) { for k in 0..<segs {
            let a = UInt32(i) * row + UInt32(k)
            s.quad(a, a + 1, a + row + 1, a + row)
        }}
        s.recomputeNormals(); s.computeTangents()
        return s
    }

    /// Surface from a grid of points; normal = cross(d column, d row).
    static func grid(_ rows: [[V3]], material: MaterialKey, uvScale: Float = 1) -> Surface {
        var s = Surface(material: material)
        for (i, row) in rows.enumerated() { for (k, p) in row.enumerated() { _ = s.add(p, .up, V2(p.x + Float(k) * 0.0, p.z) * uvScale + V2(0, Float(i) * 0.0)) } }
        let w = UInt32(rows[0].count)
        for i in 0..<(rows.count - 1) { for k in 0..<(Int(w) - 1) {
            let a = UInt32(i) * w + UInt32(k)
            s.quad(a, a + 1, a + w + 1, a + w)
        }}
        s.recomputeNormals(); s.computeTangents()
        return s
    }

    /// Bracket-fungus fan in local frame: root at origin, grows along +x, top faces +y, 2-3 mm thin rim.
    /// zones: (first row, material) for concentric color bands.
    static func fan(R: Float, spread: Float, thick: Float, droop: Float, rows: Int, cols: Int, edge: Float,
                    zones: [(Int, MaterialKey)], under: MaterialKey, rng: inout SeededRNG) -> [Surface] {
        let nz = Noise(&rng, harmonics: [2, 3, 5, 8], amp: edge)
        let ph = rng.float(0...6.28)
        var top: [[V3]] = [], bot: [[V3]] = []
        for i in 0...rows {
            var tr: [V3] = [], br: [V3] = []
            let f = 0.07 + 0.93 * Float(i) / Float(rows)
            for k in 0...cols {
                let t = Float(k) / Float(cols), th = (t * 2 - 1) * spread
                let Rt = R * (0.6 + 0.4 * cos(th / spread * .pi / 2)) * (1 + nz.v(t * 2 * .pi))
                let r = f * Rt, tk = thick * (1 - 0.82 * f)
                let y = -droop * f * f * R + sin(f * 11 + th * 3 + ph) * thick * 0.3 * f
                tr.append(V3(r * cos(th), y + tk * 0.5, r * sin(th)))
                let rb = i == rows ? r * 0.985 : r
                br.append(V3(rb * cos(th), y - tk * 0.5, rb * sin(th)))
            }
            top.append(tr); bot.append(br)
        }
        var out: [Surface] = []
        for (j, z) in zones.enumerated() {
            let end = j + 1 < zones.count ? zones[j + 1].0 : rows
            out.append(grid(Array(top[z.0...end]), material: z.1, uvScale: 1))
        }
        out.append(grid(bot.map { Array($0.reversed()) }, material: under, uvScale: 1))
        out.append(grid([top[rows], bot[rows]], material: zones.last!.1, uvScale: 1))
        return out
    }

    /// Rotation with local +x along `x` and +y as close to `up` as possible.
    static func frame(x: V3, up: V3) -> simd_quatf {
        let xa = simd_normalize(x), ya = simd_normalize(up - xa * simd_dot(up, xa))
        return simd_quatf(simd_float3x3(columns: (xa, ya, simd_cross(xa, ya))))
    }

    /// Log along local +Y from 0 to L (wobbly, tapered, with end grain discs). Returns surfaces and the radius.
    static func log(L: Float, r: Float, segs: Int, rings: Int, rng: inout SeededRNG) -> [Surface] {
        let nz = Noise(&rng, harmonics: [2, 3, 5, 7], amp: 0.05)
        let prof = (0...rings).map { j -> V2 in
            let f = Float(j) / Float(rings)
            return V2(r * (1 - 0.07 * f) * rng.float(0.97...1.03), L * f)
        }
        let wob: (Float, Float) -> Float = { a, _ in 1 + nz.v(a) }
        let body = revolve(prof, segs: segs, material: "wood.deadwood", wob: wob)
        let b = revolve([V2(0, -0.001), V2(prof[0].x, -0.001)], segs: segs, material: "wood.endgrain", wob: wob)
        let t = revolve([V2(prof[rings].x, L + 0.001), V2(0, L + 0.001)], segs: segs, material: "wood.endgrain", wob: wob)
        return [body, b, t]
    }
}
