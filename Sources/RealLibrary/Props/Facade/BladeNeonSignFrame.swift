import simd
import Foundation

/// Blade neon sign frame, Art Deco: 500 mm wide, 1.2 m high, 100 mm deep. A deep blue enameled steel can with chrome
/// edge rails and a three-step ziggurat crown, a recessed face with a chrome step line, vertical neon border tubes on
/// glass-tube supports, a sunburst fan at the top, stacked neon lettering "HOTEL" with dark electrode caps, a gray
/// transformer box with a conduit run, and bolted wall flanges. Wear: one letter stroke gone dark (dead tube), chipped
/// enamel to steel at the base, rust bleed under the seams, dust and bird lime on the crown steps.
public struct BladeNeonSignFrame: RealAsset {
    public static let id = "blade-neon-sign-frame"
    public static let summary = "Blade neon sign frame, Art Deco facade prop, 0.5 x 1.2 x 0.1 m."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 2.2)

    /// Can enamel.
    public var enamel: MaterialKey = "metal.painted:1B2B4C"
    /// Lettering tube glow.
    public var glow: MaterialKey = "emissive.signal-red"
    /// Border tube glow.
    public var border: MaterialKey = "emissive.signal-orange"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.5, dC: Float = 0.077
        let y0: Float = 0.1, y1: Float = 1.08
        let cyC = (y0 + y1) / 2, hC = y1 - y0
        // Can body: shell with a recessed face and chrome rails on both long edges.
        FA.box(&m, V3(W, hC, dC), V3(0, cyC, dC / 2), enamel, r: 0.006)
        FA.box(&m, V3(W - 0.07, hC - 0.07, 0.004), V3(0, cyC, dC + 0.0005), "metal.painted:101E3C", r: 0.0015)
        for sgn: Float in [-1, 1] {
            FA.box(&m, V3(0.014, hC + 0.004, dC + 0.008), V3(sgn * (W / 2 - 0.007), cyC, dC / 2), "metal.chrome", r: 0.0035)
        }
        FA.box(&m, V3(W, 0.014, dC + 0.008), V3(0, y0 + 0.004, dC / 2), "metal.chrome", r: 0.0035)
        FA.box(&m, V3(W, 0.014, dC + 0.008), V3(0, y1 - 0.004, dC / 2), "metal.chrome", r: 0.0035)
        // Chrome step line inside the face, rivets along it.
        var frame: [V3] = []
        for p in Shape2D.rounded([V2(-0.205, y0 + 0.04), V2(0.205, y0 + 0.04), V2(0.205, y1 - 0.04), V2(-0.205, y1 - 0.04)], radius: 0.015, segments: 4) { frame.append(V3(p.x, p.y, dC + 0.0032)) }
        m.add(Prim.sweep(Shape2D.circle(0.0028, segments: 6), along: frame, up: FA.Z, closedPath: true, caps: false, material: "metal.chrome"))
        rivetRow(&m, along: frame + [frame[0]], spacing: 0.095, normal: { _ in FA.Z }, radius: 0.0034, material: "metal.chrome")
        // Ziggurat crown: three stepped blocks with a chrome cap line each.
        let steps: [(Float, Float)] = [(0.4, 0.04), (0.3, 0.04), (0.2, 0.04)]
        var yy = y1
        for (w, h) in steps {
            FA.box(&m, V3(w, h, dC * 0.9), V3(0, yy + h / 2, dC * 0.45), enamel, r: 0.004)
            FA.box(&m, V3(w + 0.008, 0.007, dC * 0.9 + 0.008), V3(0, yy + h - 0.0015, dC * 0.45), "metal.chrome", r: 0.002)
            yy += h
        }
        // Neon: vertical border tubes with electrode caps, support clips every 0.13 m.
        let zN: Float = dC + 0.0105
        let tr: Float = 0.0062
        for sgn: Float in [-1, 1] {
            let x = sgn * 0.215
            let top = y1 - 0.12
            FA.path(&m, [V3(x, y0 + 0.07, zN), V3(x, top - 0.02, zN), V3(x - sgn * 0.012, top, zN), V3(x - sgn * 0.045, top + 0.008, zN)], r: tr, border, sides: 8)
            m.add(Prim.cylinder(radius: 0.0085, height: 0.014, bevel: 0.002, segments: 10, bevelSegments: 1, material: "metal.painted:1B1B1D"), Xform(translation: V3(x, y0 + 0.056, zN), rotation: FA.q(0, FA.X)))
            var y = y0 + 0.14
            while y < top {
                FA.box(&m, V3(0.018, 0.012, 0.012), V3(x, y, dC + 0.004), "metal.chrome", r: 0.002)
                FA.box(&m, V3(0.014, 0.0045, 0.0058), V3(x, y, zN - 0.003), "metal.painted:2A2A2D", r: 0.001)
                y += 0.13
            }
        }
        // Chevron rungs between the border tubes and the lettering zone.
        for yc: Float in [y0 + 0.065, y0 + 0.865] {
            FA.path(&m, [V3(-0.205, yc, zN), V3(0, yc + 0.035, zN), V3(0.205, yc, zN)], r: tr, border, sides: 8)
        }
        // Sunburst fan at the top.
        for k in 0..<7 {
            let a = (20 + Float(k) * 23.3) * .pi / 180
            let c = V3(0, y1 - 0.06, zN)
            FA.rod(&m, c + V3(cos(a), sin(a), 0) * 0.03, c + V3(cos(a), sin(a), 0) * 0.095, r: 0.0048, border, sides: 6)
        }
        m.add(Prim.torus(major: 0.022, minor: 0.0048, segments: 20, sides: 6, arc: .pi, material: border), Xform(translation: V3(0, y1 - 0.06, zN), rotation: FA.q(90, FA.X)))
        // Stacked lettering H O T E L with dark electrode caps at stroke ends.
        let h: Float = 0.112, gap: Float = 0.03
        let word = Array("HOTEL")
        let top0 = y1 - 0.17
        for (i, ch) in word.enumerated() {
            let y = top0 - Float(i + 1) * h - Float(i) * gap
            let w = FS.width(String(ch), h: h, ws: 0.95)
            let r = FS.segments(String(ch), origin: V2(-w / 2, y), h: h, ws: 0.95)
            for (si, (a, b)) in r.segs.enumerated() {
                let dead = (i == 3 && si == 2)       // one dead tube in the second E
                FA.rod(&m, V3(a.x, a.y, zN), V3(b.x, b.y, zN), r: tr, dead ? "glass.frosted" : glow, sides: 8)
                if si == r.segs.count - 1 || si == 0 {
                    m.add(Prim.cylinder(radius: 0.0085, height: 0.01, bevel: 0.002, segments: 8, bevelSegments: 1, material: "metal.painted:1B1B1D"), Xform(translation: V3(a.x, a.y, zN - 0.012), rotation: FA.q(90, FA.X)))
                }
                FC.bead(&m, r: tr * 1.02, at: V3(b.x, b.y, zN), dead ? "glass.frosted" : glow, sub: 2)
                if si % 3 == 0 {
                    FA.box(&m, V3(0.009, 0.009, 0.012), V3((a.x + b.x) / 2, (a.y + b.y) / 2, dC + 0.004), "metal.chrome", r: 0.0015)
                }
            }
        }
        // Transformer box under the can with a conduit and clamps, wall flanges at top and bottom.
        FA.box(&m, V3(0.15, 0.092, 0.07), V3(0.1, 0.046, 0.035), "metal.painted:6B6F73", r: 0.004)
        FA.box(&m, V3(0.15, 0.012, 0.074), V3(0.1, 0.092, 0.037), "metal.painted:595D61", r: 0.003)
        for dx: Float in [-0.055, 0.055] { FS.screw(&m, at: V3(0.1 + dx, 0.046, 0.0702), r: 0.0048, "metal.steel", angle: rng.float(0...180)) }
        FA.rod(&m, V3(0.06, 0.092, 0.035), V3(0.06, y0 + 0.008, 0.035), r: 0.008, "metal.galvanized-aged", sides: 8)
        for sy: Float in [0.125, 0.5, 1.0] { FA.box(&m, V3(0.016, 0.01, 0.01), V3(0.06, sy, 0.04), "metal.steel", r: 0.002) }
        for (sx, yb) in [(-1, y0 + 0.07), (1, y0 + 0.07), (-1, y1 - 0.07), (1, y1 - 0.07)] as [(Float, Float)] {
            hexBolt(&m, at: V3(sx * 0.2, yb, dC + 0.0092), normal: FA.Z, size: 0.012, material: "metal.bolt-bright")
        }
        // Weathering: enamel chips to steel near the base, rust bleed from the seams, dust and bird lime on the crown.
        for _ in 0..<12 {
            FS.blob(&m, at: V3(rng.float(-0.2...0.2), rng.float(y0 + 0.02...y0 + 0.2), dC + 0.0026), size: V3(rng.float(0.008...0.022), rng.float(0.006...0.014), 0.0008), rng.chance(0.5) ? "metal.steel" : "metal.rust")
        }
        for sgn: Float in [-1, 1] { FS.blob(&m, at: V3(sgn * 0.233, y0 + 0.3, dC + 0.0027), size: V3(0.008, rng.float(0.1...0.2), 0.0008), "metal.rust-grime") }
        for (k, (w, h)) in steps.enumerated() {
            let ytop = y1 + Float(k) * 0.04 + h
            FS.blob(&m, at: V3(rng.float(-w / 3...w / 3), ytop + 0.0008, dC * 0.45), size: V3(rng.float(0.03...0.07), 0.0014, 0.02), rng.chance(0.5) ? "stone.limestone" : "stone.limestone-sooted")
        }
        FS.blob(&m, at: V3(0, y0 + 0.012, dC + 0.0028), size: V3(0.3, 0.012, 0.0012), "stone.limestone-sooted")
        groundAO(&m)
        return LODModel(FC.place(m))
    }
}
