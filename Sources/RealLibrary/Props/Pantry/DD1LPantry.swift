import simd
import Foundation

/// Shared geometry helpers for the pantry props (sheets, cylinder patches, foil bags, scuffs).
enum DD1LPantry {
    static func q(_ a: Float, _ axis: V3) -> simd_quatf { simd_quatf(angle: a, axis: axis) }

    /// Parametric sheet from (u, v) in 0...1 to a position; faces +Z when u maps to +x and v to +y.
    static func grid(cols: Int, rows: Int, material: MaterialKey, _ f: (Float, Float) -> V3) -> Surface {
        var s = Surface(material: material)
        for j in 0...rows { for i in 0...cols {
            let p = f(Float(i) / Float(cols), Float(j) / Float(rows))
            _ = s.add(p, V3(0, 0, 1), V2(p.x, p.y))
        } }
        let row = UInt32(cols + 1)
        for j in 0..<UInt32(rows) { for i in 0..<UInt32(cols) { let a = j * row + i; s.quad(a, a + 1, a + row + 1, a + row) } }
        s.recomputeNormals()
        s.computeTangents()
        return s
    }

    /// Slightly pillowed, creased paper panel in the local XY plane facing +Z.
    static func panel(w: Float, h: Float, bulge: Float, seed: UInt32, cols: Int, rows: Int, material: MaterialKey) -> Surface {
        grid(cols: cols, rows: rows, material: material) { u, v in
            let x = (u - 0.5) * w, y = (v - 0.5) * h
            let b = bulge * (1 - pow(2 * x / w, 2)) * (1 - pow(2 * y / h, 2))
            let c = 0.00035 * Noise.perlin(V3(x * 55, y * 55, 0), seed: seed)
            return V3(x, y, b + c)
        }
    }

    /// Printed panels on the four vertical faces of a box (front, back, right, left order in `mats`).
    static func facePanels(_ m: inout Model, size: V3, center: V3, inset: Float, bulge: Float, seed: UInt32,
                           mats: [MaterialKey], detail: Bool) {
        let hx = size.x / 2, hz = size.z / 2, ph = size.y - 2 * inset
        let faces: [(Float, Float, simd_quatf, V3)] = [
            (size.x - 2 * inset, hz, q(0, V3(0, 1, 0)), V3(0, 0, hz)),
            (size.x - 2 * inset, hz, q(.pi, V3(0, 1, 0)), V3(0, 0, -hz)),
            (size.z - 2 * inset, hx, q(.pi / 2, V3(0, 1, 0)), V3(hx, 0, 0)),
            (size.z - 2 * inset, hx, q(-.pi / 2, V3(0, 1, 0)), V3(-hx, 0, 0)),
        ]
        for (i, f) in faces.enumerated() {
            let s = panel(w: f.0, h: ph, bulge: bulge, seed: seed &+ UInt32(i), cols: detail ? 14 : 4, rows: detail ? 14 : 4, material: mats[i])
            m.add(s, Xform(translation: center + f.3 + f.2.act(V3(0, 0, 0.0002)), rotation: f.2))
        }
    }

    /// Patch hugging a cylinder of radius `r` (angles a0 < a1, radians, +Z is angle -pi/2 ... use a = pi/2 for front).
    static func cylPatch(r: Float, a0: Float, a1: Float, y0: Float, y1: Float, lift: Float = 0.0003, rows: Int = 2,
                         material: MaterialKey, radiusAt: ((Float) -> Float)? = nil) -> Surface {
        let cols = max(2, Int(abs(a1 - a0) / 0.1))
        var s = Surface(material: material)
        for j in 0...rows { for i in 0...cols {
            let a = a0 + (a1 - a0) * Float(i) / Float(cols), y = y0 + (y1 - y0) * Float(j) / Float(rows)
            let rr = (radiusAt?(y) ?? r) + lift
            _ = s.add(V3(rr * cos(a), y, -rr * sin(a)), V3(cos(a), 0, -sin(a)), V2(a * r, y))
        } }
        let row = UInt32(cols + 1)
        for j in 0..<UInt32(rows) { for i in 0..<UInt32(cols) { let a = j * row + i; s.quad(a, a + 1, a + row + 1, a + row) } }
        s.recomputeNormals()
        s.computeTangents()
        return s
    }

    /// Lathe profile for a full-height band of radius r with `rows` rows (dense so dents carry through).
    static func band(r: Float, y0: Float, y1: Float, rows: Int) -> [V2] {
        (0...rows).map { V2(r, y0 + (y1 - y0) * Float($0) / Float(rows)) }
    }

    /// Short scuffs along the vertical edges of a box (printed layer worn to the board).
    static func edgeScuffs(_ m: inout Model, size: V3, center: V3, count: Int, rng: inout SeededRNG, material: MaterialKey) {
        for _ in 0..<count {
            let sx: Float = rng.chance(0.5) ? -1 : 1, sz: Float = rng.chance(0.5) ? -1 : 1
            let len = rng.float(0.006...0.022)
            let y = center.y + rng.float(-0.5...0.5) * (size.y - len)
            m.add(Prim.roundedBox(V3(0.0026, len, 0.0026), radius: 0.0007, bevelSegments: 1, material: material),
                  Xform(translation: V3(center.x + sx * (size.x / 2 - 0.0004), y, center.z + sz * (size.z / 2 - 0.0004))))
        }
    }

    /// Double-sided crimped plate (local XY, thickness along Z): ribs run across the width, stepping along Y.
    static func crimp(w: Float, h: Float, thick: Float, period: Float, amp: Float, detail: Bool, material: MaterialKey,
                      shift: (Float) -> Float = { _ in 0 }) -> Surface {
        let rows = max(2, Int(h / period * (detail ? 3 : 1)))
        let front = grid(cols: 2, rows: rows, material: material) { u, v in
            let y = (v - 0.5) * h
            return V3((u - 0.5) * w + shift(y), y, thick / 2 + amp * sin(y * 2 * .pi / period))
        }
        var back = grid(cols: 2, rows: rows, material: material) { u, v in
            let y = (v - 0.5) * h
            return V3((u - 0.5) * w + shift(y), y, -thick / 2 - amp * sin(y * 2 * .pi / period))
        }
        back = back.flipped()
        var s = front
        s.append(back)
        return s
    }
}

/// Foil bag: loft body with dense crimp zones, wrinkle displacement and conforming print patches.
struct DD1LBag {
    var w: Float, h: Float, depth: Float
    var topSeal: Float, botSeal: Float
    var pillow: Bool
    var seed: UInt32
    var material: MaterialKey
    static let flat: Float = 0.0036

    func t(_ y: Float) -> Float { min(1, max(0, (y - botSeal) / (h - botSeal - topSeal))) }
    func top(_ y: Float) -> Float { smoothstep(h - topSeal - 0.075, h - topSeal, y) }
    func d(_ y: Float) -> Float {
        if pillow { return Self.flat + (depth - Self.flat) * pow(max(0, sin(.pi * t(y))), 0.55) }
        return Self.flat + (depth * (y < 0.002 ? 0.94 : 1) - Self.flat) * (1 - top(y))
    }
    func wd(_ y: Float) -> Float { pillow ? w * (1 - 0.09 * pow(max(0, sin(.pi * t(y))), 0.8)) : w * (1 - 0.06 * top(y)) }
    func ex(_ y: Float) -> Float { pillow ? 2.4 + 3.6 * (1 - pow(max(0, sin(.pi * t(y))), 0.6)) : 5 + 4 * top(y) }

    func wrinkle(_ p: V3) -> Float {
        let lo = max(botSeal, 0.002)
        let zone = smoothstep(lo, lo + 0.012, p.y) * (1 - smoothstep(h - topSeal - 0.012, h - topSeal, p.y))
        let c = Noise.ridged(V3(p.x * 38, p.y * 22, p.z * 38), octaves: 3, seed: seed) - 0.45
        return 0.0023 * c * zone
    }

    func levels(detail: Bool) -> [Float] {
        let step: Float = detail ? 0.0011 : 0.005
        var ys: [Float] = []
        var y: Float = 0
        if botSeal > 0 { while y < botSeal { ys.append(y); y += step } } else { ys = [0, 0.0015] }
        let b0 = max(botSeal, 0.004), b1 = h - topSeal, n = detail ? 30 : 8
        for i in 0..<n { ys.append(b0 + (b1 - b0) * Float(i) / Float(n)) }
        y = b1
        while y < h - 0.0001 { ys.append(y); y += step }
        ys.append(h)
        return ys
    }

    func surface(detail: Bool, sides: Int) -> Surface {
        let rings: [[V3]] = levels(detail: detail).map { y in
            let inset: Float = y < 0.0015 ? 0.004 : 0
            return Prim.ring(Shape2D.superellipse(wd(y) - inset, max(0.002, d(y) - inset), exponent: ex(y), segments: sides), y: y)
        }
        var s = Prim.loft(rings, capStart: true, capEnd: true, material: material)
        let hh = h, ts = topSeal, bs = botSeal
        s.displace { p, _ in
            var o = self.wrinkle(p)
            if p.y > hh - ts || p.y < bs { o += 0.0007 * sin(p.y * 2 * .pi / 0.0033) }
            return o
        }
        s.uvs = s.positions.map { V2($0.x + $0.z, $0.y) }
        s.computeTangents()
        return s
    }

    func frontZ(_ x: Float, _ y: Float) -> Float {
        let n = ex(y), hw = wd(y) / 2
        return d(y) / 2 * pow(max(0, 1 - pow(abs(x) / hw, n)), 1 / n)
    }

    /// Print patch conforming to the front (or back) panel. `round` maps the grid to an ellipse.
    func patch(w pw: Float, h ph: Float, cx: Float = 0, cy: Float, lift: Float = 0.0005, back: Bool = false,
               round: Bool = false, ripple: Float = 0, cols: Int, rows: Int, material: MaterialKey) -> Surface {
        let sg: Float = back ? -1 : 1
        let s = DD1LPantry.grid(cols: cols, rows: rows, material: material) { u, v in
            var a = u * 2 - 1, b = v * 2 - 1
            if round { let ra = a * sqrt(max(0, 1 - b * b / 2)); b = b * sqrt(max(0, 1 - a * a / 2)); a = ra }
            let x = cx + a * pw / 2, y = cy + b * ph / 2
            let z = frontZ(x, y)
            let rp = ripple * sin(a * 7 + b * 3)
            return V3(x, y, sg * (z + lift + wrinkle(V3(x, y, sg * z)) + rp))
        }
        return back ? s.flipped() : s
    }
}
