import simd
import RealCore

/// Lofted fish body, lower jaw and eyes in the `FishShape` building frame (snout at x = 0, tail toward -X).
/// Skin UVs follow the fish atlas: u around the body (0 dorsal, 0.5 ventral), v 1 at the snout to 0 at the tail.
enum FishBody {
    /// Body positions for `count` rings over `range`, denser at the head.
    static func stations(_ range: ClosedRange<Float>, count: Int) -> [Float] {
        (0...count).map { i in
            let u = Float(i) / Float(count)
            let g = 0.55 * u + 0.45 * u * u
            return range.lowerBound + (range.upperBound - range.lowerBound) * g
        }
    }

    /// Gill cover groove and the slight step behind it, as a lateral scale factor.
    static func gillFactor(_ f: FishShape, _ s: Float, _ y: Float) -> Float {
        let yn = y / max(f.halfDepth(s), 1e-4)
        guard abs(yn) < 0.92 else { return 1 }
        let d = s - (f.operculum - 0.035 * yn * yn)
        let groove = 0.045 * exp(-(d / 0.008) * (d / 0.008))
        let step = d > 0 ? 0.015 * (1 - smoothstep(0.0, 0.08, d)) : 0
        return 1 - groove - step
    }

    /// Ring point with the head clamped above the mouth line (palate) when `palate` is set, or below it for the jaw.
    static func ringPoint(_ f: FishShape, _ s: Float, _ th: Float, mode: Int) -> (V3, Bool) {
        var p = f.point(s, th)
        var clamped = false
        if mode != 0 && s <= f.mouthEnd + 1e-4 {
            let ml = f.mouthLine(s)
            if mode == 1 && p.y < ml { p.y = ml; clamped = true }
            if mode == 2 && p.y > ml - 0.0004 * f.length { p.y = ml - 0.0004 * f.length; clamped = true }
        }
        p.z *= gillFactor(f, s, p.y)
        return (p, clamped)
    }

    /// Lofted skin over `range`. mode 0 plain, 1 body head with palate, 2 lower jaw.
    /// Quads whose corners are all clamped go to `mouth` (palate roof / tongue).
    static func loft(_ f: FishShape, _ range: ClosedRange<Float>, rings: Int, sides: Int, mode: Int,
                     capFront: Bool, capBack: Bool, xShift: ((Float) -> Float)? = nil) -> [Surface] {
        var skin = Surface(material: f.skin), mouth = Surface(material: "fish.mouth")
        let ss = stations(range, count: rings)
        var grid: [[V3]] = [], flags: [[Bool]] = []
        for s in ss {
            var row: [V3] = [], fl: [Bool] = []
            for j in 0...sides {
                let th = Float(j) / Float(sides) * 2 * .pi
                var (p, c) = ringPoint(f, s, th, mode: mode)
                if let xs = xShift { p.x += xs(s) }
                row.append(p); fl.append(c)
            }
            grid.append(row); flags.append(fl)
        }
        func uv(_ i: Int, _ j: Int) -> V2 { V2(Float(j) / Float(sides), 1 - ss[i] * 0.95) }
        for i in 0..<(grid.count - 1) {
            for j in 0..<sides {
                let allC = flags[i][j] && flags[i][j + 1] && flags[i + 1][j] && flags[i + 1][j + 1]
                let corners = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)]
                if allC {
                    let idx = corners.map { mouth.add(grid[$0.0][$0.1], .zero, uv($0.0, $0.1)) }
                    mouth.quad(idx[0], idx[1], idx[2], idx[3])
                } else {
                    let idx = corners.map { skin.add(grid[$0.0][$0.1], .zero, uv($0.0, $0.1)) }
                    skin.quad(idx[0], idx[1], idx[2], idx[3])
                }
            }
        }
        // Rings run snout -> tail (toward -X); with theta increasing toward +Z this winding faces outward.
        func cap(_ row: [V3], _ i: Int, tip: V3, flip: Bool) {
            let c = skin.add(tip, .zero, V2(0.02, 1 - ss[i] * 0.95))
            for j in 0..<sides {
                let a = skin.add(row[j], .zero, uv(i, j)), b = skin.add(row[j + 1], .zero, uv(i, j + 1))
                if flip { skin.tri(c, b, a) } else { skin.tri(c, a, b) }
            }
        }
        if capFront {
            let row = grid[0]
            var tip = row.reduce(V3.zero, +) / Float(row.count)
            tip.x += 0.012 * f.length
            cap(row, 0, tip: tip, flip: false)
        }
        if capBack {
            let row = grid[grid.count - 1]
            var tip = row.reduce(V3.zero, +) / Float(row.count)
            tip.x -= 0.002 * f.length
            cap(row, grid.count - 1, tip: tip, flip: true)
        }
        skin = welded(skin); mouth = welded(mouth)
        return [skin, mouth].filter { !$0.isEmpty }
    }

    /// Merge coincident vertices with equal UVs so normals smooth across quads, then recompute normals.
    static func welded(_ s: Surface) -> Surface {
        guard !s.isEmpty else { return s }
        var out = Surface(material: s.material)
        var map: [SIMD4<Int32>: UInt32] = [:]
        var remap = [UInt32](repeating: 0, count: s.positions.count)
        for i in s.positions.indices {
            let p = s.positions[i] * 1e5, uv = s.uvs[i] * 1e4
            let k = SIMD4<Int32>(Int32(p.x.rounded()), Int32(p.y.rounded()), Int32(p.z.rounded()),
                                 Int32((uv.x * 7 + uv.y * 13).rounded()))
            if let e = map[k] { remap[i] = e } else { let n = out.add(s.positions[i], .zero, s.uvs[i]); map[k] = n; remap[i] = n }
        }
        out.indices = s.indices.map { remap[Int($0)] }
        out.recomputeNormals()
        return out
    }

    /// Domed eye on both sides of the head.
    static func eyes(_ f: FishShape, detail: Int) -> Surface {
        var e = Surface(material: f.eye)
        let r = f.eyeR * f.length
        let s = f.eyeAt
        let y = f.top(s) * f.eyeY
        let zs = f.surfaceZ(s, y: y) * gillFactor(f, s, y)
        let rings = 3 + detail * 3, seg = 10 + detail * 8
        for side in [Float(1), -1] {
            let c = V3(f.x(s), y, side * (zs - 0.45 * r))
            let base = UInt32(e.positions.count)
            for i in 0...rings {
                let phi = Float(i) / Float(rings) * radians(100)
                for j in 0...seg {
                    let a = Float(j) / Float(seg) * 2 * .pi
                    let d = V3(sin(phi) * cos(a), sin(phi) * sin(a), cos(phi))
                    let p = c + V3(d.x * r, d.y * r, side * d.z * r * 0.62)
                    let k: Float = phi > .pi / 2 ? 0.5 : sin(phi) * 0.5
                    let n = simd_normalize(V3(d.x, d.y, side * d.z / 0.62))
                    e.add(p, n, V2(0.5 + side * cos(a) * k, 0.5 + sin(a) * k))
                }
            }
            let w = UInt32(seg + 1)
            for i in 0..<UInt32(rings) {
                for j in 0..<UInt32(seg) {
                    let a = base + i * w + j, b = a + 1, c2 = a + w, d = c2 + 1
                    if i == 0 { if side > 0 { e.tri(a, c2, d) } else { e.tri(a, d, c2) }; continue }
                    if side > 0 { e.quad(a, c2, d, b) } else { e.quad(a, b, d, c2) }
                }
            }
        }
        return e
    }
}
