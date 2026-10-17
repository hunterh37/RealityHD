import simd
import Foundation

/// Boston Common Visitor Information Center (Tremont St.): a 6 x 4 m single-storey pavilion on a
/// granite plinth. Clapboard dado, a continuous band of multi-pane windows, glazed front door,
/// trim boards, a hip roof in asphalt shingle courses with deep eaves, and a green signboard.
public struct VisitorKiosk: RealAsset {
    public static let id = "visitor-kiosk"
    public static let summary = "Boston Common Visitor Information Center on Tremont St: small single-storey pavilion with painted wood siding, large windows, hip roof and signage."
    public static let tags = ["prop", "building", "park", "wood", "sign", "roof"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 1.1)

    /// Footprint width (X) in meters, walls outside face.
    public var width: Float = 5.2
    /// Footprint depth (Z) in meters.
    public var depth: Float = 3.2
    /// Eave height above grade in meters.
    public var eave: Float = 2.95
    /// Roof pitch rise in meters above the eave.
    public var rise: Float = 1.25
    /// Eave overhang in meters.
    public var overhang: Float = 0.4
    /// Siding material key.
    public var siding: MaterialKey = "wood.painted-exterior:D8D2C2"
    /// Trim and mullion material key.
    public var trim: MaterialKey = "wood.painted-exterior:2E4637"
    /// Roof material key.
    public var roof: MaterialKey = "stone.slate"
    /// Glazing material key.
    public var glass: MaterialKey = "glass.pane"
    /// Plinth stone material key.
    public var stone: MaterialKey = "stone.granite-curb"
    /// Signboard material key.
    public var sign: MaterialKey = "sign.green-worn"
    /// Sign lettering material key.
    public var lettering: MaterialKey = "paint.field-white"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = width / 2, hz = depth / 2
        let plinth: Float = 0.3
        // Granite plinth with a step at the door.
        m.add(Prim.roundedBox(V3(width + 0.2, plinth, depth + 0.2), radius: 0.015, bevelSegments: 1, material: stone), Xform(translation: V3(0, plinth / 2, 0)))
        m.add(Prim.roundedBox(V3(1.6, 0.15, 0.4), radius: 0.012, bevelSegments: 1, material: stone), Xform(translation: V3(0, 0.075, hz + 0.3)))
        let sill: Float = plinth + 0.75, head: Float = eave - 0.55
        let t: Float = 0.16
        func box(_ size: V3, _ c: V3, _ mat: MaterialKey, _ r: Float = 0.006) {
            if r <= 0.004 {
                m.add(Prim.extrude(Shape2D.rect(size.x, size.y), depth: size.z, bevel: 0, bevelSegments: 0, material: mat), Xform(translation: c))
            } else {
                m.add(Prim.roundedBox(size, radius: r, bevelSegments: 1, material: mat), Xform(translation: c))
            }
        }
        // Walls per side: (axis length, along X?, outward sign).
        let sides: [(Float, Bool, Float)] = [(width, true, 1), (width, true, -1), (depth, false, 1), (depth, false, -1)]
        for (si, (len, alongX, sgn)) in sides.enumerated() {
            func at(_ u: Float, _ y: Float, _ out: Float) -> V3 { alongX ? V3(u, y, sgn * (hz - t / 2) + sgn * out) : V3(sgn * (hx - t / 2) + sgn * out, y, u) }
            func sz(_ l: Float, _ h: Float, _ d: Float) -> V3 { alongX ? V3(l, h, d) : V3(d, h, l) }
            let inner = len - 2 * t
            let isFront = si == 0
            // Dado (clapboard) below the sill, header above the windows.
            if isFront {
                let seg = (inner - 1.1) / 2
                for s in [Float(-1), 1] { box(sz(seg, sill - plinth, t), at(s * (0.55 + seg / 2), (sill + plinth) / 2, 0), siding) }
            } else {
                box(sz(inner, sill - plinth, t), at(0, (sill + plinth) / 2, 0), siding)
            }
            box(sz(inner, eave - head, t), at(0, (eave + head) / 2, 0), siding)
            // Clapboard reveal lines: thin trim strips every 12 cm on the dado and header.
            var y = plinth + 0.12
            while y < eave - 0.05 {
                if y < sill - 0.02 || y > head + 0.02 {
                    if isFront && y < sill { for s in [Float(-1), 1] {
                        let seg = (inner - 1.1) / 2
                        box(sz(seg, 0.012, 0.012), at(s * (0.55 + seg / 2), y, t / 2), siding, 0.004) } }
                    else { box(sz(inner, 0.012, 0.012), at(0, y, t / 2), siding, 0.004) }
                }
                y += 0.12
            }
            // Sill and head trim.
            box(sz(len + 0.04, 0.05, 0.07), at(0, sill + 0.025, t / 2 + 0.01), trim)
            box(sz(len + 0.02, 0.12, 0.04), at(0, head - 0.06, t / 2), trim)
            // Window band: mullions and glass, door opening on the front.
            let bayW: Float = 0.62
            let n = Int((inner / bayW).rounded())
            let bw = inner / Float(n)
            for i in 0...n {
                let u = -inner / 2 + Float(i) * bw
                if isFront && abs(u) < 0.5 { continue }
                box(sz(0.07, head - sill, 0.1), at(u, (sill + head) / 2, 0.01), trim)
            }
            // Muntin rail at two-thirds height.
            let rail = sill + (head - sill) * 0.68
            if isFront {
                for s in [Float(-1), 1] { box(sz(inner / 2 - 0.55, 0.035, 0.05), at(s * (0.55 + (inner / 2 - 0.55) / 2), rail, 0.01), trim) }
            } else {
                box(sz(inner, 0.035, 0.05), at(0, rail, 0.01), trim)
            }
            box(sz(inner, head - sill, 0.012), at(0, (sill + head) / 2, -0.03), glass)
            // Corner boards.
            for s in [Float(-1), 1] { box(sz(0.14, eave - plinth, 0.03), at(s * (len / 2 - 0.07), (eave + plinth) / 2, t / 2 + 0.005), trim) }
            if isFront {
                // Glazed door: stiles, rails, kick panel, handle.
                let dw: Float = 0.96, dh: Float = 2.15
                for s in [Float(-1), 1] { box(sz(0.09, dh, 0.06), at(s * (dw / 2 - 0.045), plinth + dh / 2, 0), trim) }
                box(sz(dw, 0.3, 0.06), at(0, plinth + 0.15, 0), trim)
                box(sz(dw, 0.1, 0.06), at(0, plinth + dh - 0.05, 0), trim)
                box(sz(dw - 0.18, dh - 0.4, 0.012), at(0, plinth + 0.3 + (dh - 0.4) / 2, -0.005), glass)
                box(sz(0.03, 0.32, 0.03), at(dw / 2 - 0.16, plinth + 1.0, 0.06), "metal.brass-aged", 0.008)
                // Door casing and transom.
                box(sz(dw + 0.2, 0.1, 0.05), at(0, plinth + dh + 0.05, t / 2), trim)
                box(sz(dw, head - plinth - dh - 0.1, 0.012), at(0, (plinth + dh + 0.1 + head) / 2, -0.03), glass)
            }
        }
        // Frieze board and fascia.
        box(V3(width + 0.06, 0.22, depth + 0.06), V3(0, eave - 0.11, 0), trim)
        let ox = hx + overhang, oz = hz + overhang
        box(V3(2 * ox, 0.18, 2 * oz), V3(0, eave + 0.03, 0), trim, 0.01)
        // Hip roof: four planes in stepped shingle courses.
        let ridge = max(0.05, (width - depth) / 2 + 0.0)
        let y0 = eave + 0.12, y1 = y0 + rise
        let eaveC = [V3(-ox, y0, oz), V3(ox, y0, oz), V3(ox, y0, -oz), V3(-ox, y0, -oz)]
        let ridgeC = [V3(-ridge, y1, 0), V3(ridge, y1, 0), V3(ridge, y1, 0), V3(-ridge, y1, 0)]
        var rs = Surface(material: roof)
        let courses = 12
        for f in 0..<4 {
            let a0 = eaveC[f], b0 = eaveC[(f + 1) % 4], a1 = ridgeC[f], b1 = ridgeC[(f + 1) % 4]
            let nrm = simd_normalize(simd_cross(b0 - a0, a1 - a0))
            let ux = simd_normalize(b0 - a0)
            for c in 0..<courses {
                let t0 = Float(c) / Float(courses), t1 = Float(c + 1) / Float(courses)
                let step: V3 = nrm * 0.014
                let da: V3 = a1 - a0, db: V3 = b1 - b0
                let pa0: V3 = a0 + da * t0 + step, pb0: V3 = b0 + db * t0 + step
                let pb1: V3 = b0 + db * t1, pa1: V3 = a0 + da * t1
                let p: [V3] = [pa0, pb0, pb1, pa1]
                let base = UInt32(rs.positions.count)
                for q in p {
                    let vAxis: V3 = simd_normalize(simd_cross(nrm, ux))
                    let vv: Float = simd_dot(q - a0, vAxis)
                    rs.add(q, nrm, V2(simd_dot(q - a0, ux), vv))
                }
                rs.quad(base, base + 1, base + 2, base + 3)
            }
        }
        // Underside soffit.
        let sb = UInt32(rs.positions.count)
        for q in eaveC { rs.add(V3(q.x, y0 - 0.001, q.z), V3(0, -1, 0), V2(q.x, q.z)) }
        rs.quad(sb + 3, sb + 2, sb + 1, sb)
        rs.recomputeNormals()
        rs.computeTangents()
        m.add(rs)
        // Ridge and hip caps.
        let capR: Float = 0.035
        m.add(Prim.tube([ridgeC[0] + V3(-0.02, 0.01, 0), ridgeC[1] + V3(0.02, 0.01, 0)], radii: [capR, capR], sides: 8, seamTile: 0.3, material: roof))
        for f in 0..<4 {
            m.add(Prim.tube([eaveC[f] + V3(0, 0.02, 0), ridgeC[f] + V3(0, 0.01, 0)], radii: [capR, capR], sides: 8, seamTile: 0.3, material: roof))
        }
        // Signboard over the windows on the front, with lettering strokes and a finial lamp.
        let signZ = hz + 0.06
        box(V3(2.6, 0.42, 0.06), V3(0, head + 0.27, signZ), sign, 0.01)
        box(V3(2.7, 0.04, 0.08), V3(0, head + 0.5, signZ), trim, 0.01)
        // Two lines of painted letters: each glyph a few strokes in a 5-bar cell (reads as text at distance).
        var lr = rng.fork(9)
        func line(_ text: String, _ cy: Float, _ ch: Float) {
            let cw = ch * 0.62, gap = ch * 0.22, sw = ch * 0.16
            let total = Float(text.count) * (cw + gap) - gap
            var x = -total / 2
            for c in text {
                if c != " " {
                    let pick = lr.int(0...5)
                    let left = pick != 3, right = pick % 2 == 0 || pick == 5, top = pick != 4, mid = pick >= 2, bottom = pick != 1
                    let z = signZ + 0.032
                    if left { box(V3(sw, ch, 0.006), V3(x + sw / 2, cy, z), lettering, 0.002) }
                    if right { box(V3(sw, ch, 0.006), V3(x + cw - sw / 2, cy, z), lettering, 0.002) }
                    if top { box(V3(cw, sw, 0.006), V3(x + cw / 2, cy + ch / 2 - sw / 2, z), lettering, 0.002) }
                    if mid { box(V3(cw * 0.8, sw, 0.006), V3(x + cw * 0.45, cy, z), lettering, 0.002) }
                    if bottom { box(V3(cw, sw, 0.006), V3(x + cw / 2, cy - ch / 2 + sw / 2, z), lettering, 0.002) }
                }
                x += cw + gap
            }
        }
        line("BOSTON COMMON", head + 0.36, 0.12)
        line("VISITOR INFORMATION CENTER", head + 0.17, 0.07)
        // Half-round gutters and corner downspouts in aged copper.
        let gy = eave - 0.0
        for (a, b) in [(V3(-ox, gy, oz + 0.05), V3(ox, gy, oz + 0.05)), (V3(-ox, gy, -oz - 0.05), V3(ox, gy, -oz - 0.05))] {
            m.add(Prim.tube([a, b], radii: [0.05, 0.05], sides: 8, seamTile: 0.3, material: "metal.copper-patina"))
        }
        for sx in [Float(-1), 1] {
            let x = sx * (hx - 0.25)
            let path = [V3(x, gy, -oz - 0.05), V3(x, gy - 0.12, -oz - 0.05), V3(x, gy - 0.3, -hz - 0.07), V3(x, gy - 0.45, -hz - 0.07),
                        V3(x, plinth + 0.2, -hz - 0.07), V3(x, plinth + 0.06, -hz - 0.16), V3(x, plinth + 0.03, -hz - 0.28)]
            m.add(Prim.tube(catmull(path, per: 4), radii: Array(repeating: 0.04, count: catmull(path, per: 4).count), sides: 8, seamTile: 0.3, material: "metal.copper-patina"))
        }
        // Interior: ceiling, wood floor, service counter with brochure rack.
        box(V3(width - 2 * t - 0.02, 0.03, depth - 2 * t - 0.02), V3(0, eave - 0.2, 0), "paint.wall", 0.01)
        box(V3(width - 2 * t - 0.02, 0.02, depth - 2 * t - 0.02), V3(0, plinth + 0.01, 0), "wood.oak", 0.01)
        box(V3(2.4, 1.0, 0.6), V3(0.6, plinth + 0.5, -hz + t + 0.6), "wood.walnut", 0.01)
        box(V3(2.5, 0.04, 0.7), V3(0.6, plinth + 1.02, -hz + t + 0.6), "wood.walnut", 0.01)
        box(V3(0.8, 1.6, 0.3), V3(-hx + t + 0.2, plinth + 0.8, 0), "wood.walnut", 0.01)
        for i in 0..<4 { box(V3(0.04, 0.22, 0.25), V3(-hx + t + 0.36, plinth + 0.5 + Float(i) * 0.3, 0), "paper.sheet", 0.005) }
        // Freedom Trail red brick line marker on the plinth front.
        box(V3(0.3, 0.012, 0.18), V3(-1.4, plinth + 0.006, hz + 0.05), "brick.red", 0.003)
        groundAO(&m, height: 0.6)
        return LODModel(m)
    }
}
