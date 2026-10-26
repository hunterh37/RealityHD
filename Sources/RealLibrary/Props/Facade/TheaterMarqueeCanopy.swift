import simd
import Foundation

/// Art Deco theatre marquee canopy: a burgundy enamelled fascia carrying three changeable letter boards,
/// a stepped gilt cornice with a sunburst crown, bulb chases along the top and bottom edges, a plaster
/// soffit with recessed downlights, side fascias and four diagonal tie rods back to the wall.
public struct TheaterMarqueeCanopy: RealAsset {
    public static let id = "theater-marquee-canopy"
    public static let summary = "Art Deco marquee canopy 4.0 x 1.0 x 1.4 m: stepped fascia, changeable letter boards, bulb chase, soffit lights, tie rods."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.1)

    /// Centre board lines (A-Z, 0-9).
    public var now = ["NOW SHOWING", "CASABLANCA"]
    /// Side board lines.
    public var left = ["MATINEE", "DAILY"]
    public var right = ["ADULTS", "50C"]
    public var fascia: MaterialKey = "metal.painted:5E1A1F"
    public var gilt: MaterialKey = "metal.painted:CDBB86"
    public var soffit: MaterialKey = "metal.painted:D6CDB4"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 4.0, D: Float = 1.36, fh: Float = 0.62
        // Soffit plate and downlights.
        FA.box(&m, V3(W - 0.1, 0.04, D - 0.04), V3(0, 0.02, D / 2), soffit, r: 0.004)
        for row in 0..<2 { for i in 0..<6 {
            let x = (Float(i) - 2.5) * 0.62, z = 0.45 + Float(row) * 0.5
            m.add(Prim.cylinder(radius: 0.055, height: 0.012, bevel: 0.003, segments: 12, bevelSegments: 1, material: "metal.stainless"), Xform(translation: V3(x, -0.004, z)))
            m.add(Prim.cylinder(radius: 0.04, height: 0.006, bevel: 0.001, segments: 12, bevelSegments: 1, material: i == 3 && row == 1 ? "glass.frosted" : "emissive.warm"), Xform(translation: V3(x, -0.01, z)))
        }}
        // Front fascia and the two side fascias.
        FA.box(&m, V3(W, fh, 0.1), V3(0, fh / 2, D - 0.05), fascia, r: 0.006)
        for sx: Float in [-1, 1] { FA.box(&m, V3(0.1, fh, D), V3(sx * (W / 2 - 0.05), fh / 2, D / 2), fascia, r: 0.006) }
        FA.box(&m, V3(W - 0.2, 0.012, 0.012), V3(0, 0.006, D - 0.004), "metal.stainless", r: 0.002)
        // Letter boards: black field in a chrome frame, track grooves and white letters.
        let ez = D + 0.004
        func board(_ cx: Float, _ w: Float, _ lines: [String], _ hs: [Float], _ ys: [Float], _ dead: Int? = nil) {
            let bh: Float = 0.46, cy = fh / 2
            FA.box(&m, V3(w + 0.04, bh + 0.04, 0.012), V3(cx, cy, ez), "metal.stainless", r: 0.003)
            FA.box(&m, V3(w, bh, 0.012), V3(cx, cy, ez + 0.004), "metal.painted:0E0E10", r: 0.002)
            for (i, s) in lines.enumerated() {
                FG.flat(&m, V3(w - 0.03, 0.004, 0.002), V3(cx, cy + ys[i] - hs[i] * 0.62, ez + 0.011), "metal.steel:2A2A2E")
                FG.text(&m, s, h: hs[i], stroke: hs[i] * 0.15, depth: 0.006, at: V3(cx + rng.float(-0.004...0.004), cy + ys[i], ez + 0.0105), "sign.white:ECE8DC", rot: .identity, squeeze: min(1, (w - 0.1) / FG.width(s, h: hs[i])))
            }
        }
        board(0, 2.3, now, [0.12, 0.15], [0.11, -0.1])
        board(-1.4, 0.74, left, [0.09, 0.09], [0.1, -0.08])
        board(1.4, 0.74, right, [0.09, 0.09], [0.1, -0.08])
        // Gilt stepped cornice along the whole front, profile stepping back to the roof.
        FA.run(&m, [V2(1.28, fh), V2(D + 0.03, fh), V2(D + 0.03, fh + 0.03), V2(D, fh + 0.06), V2(D, fh + 0.08), V2(D - 0.04, fh + 0.12), V2(D - 0.04, fh + 0.16), V2(1.28, fh + 0.16)], length: W + 0.04, at: V3(0, 0, 0), gilt, bevel: 0.002)
        // Roof deck and flashing at the wall.
        FA.box(&m, V3(W - 0.06, 0.03, D - 0.14), V3(0, fh + 0.145, (D - 0.14) / 2 + 0.03), "metal.galvanized-aged", r: 0.003)
        FA.box(&m, V3(W, 0.2, 0.02), V3(0, fh + 0.14, 0.01), "metal.galvanized", r: 0.003)
        // Sunburst crown at the centre: gilt half disc with fifteen rays and a finial.
        var half: [V2] = []
        for k in 0...18 { let a = Float(k) / 18 * .pi; half.append(V2(cos(a), sin(a)) * 0.15) }
        let cz = D - 0.03, cy0 = fh + 0.16
        m.add(Prim.extrude(half, depth: 0.025, bevel: 0.004, bevelSegments: 1, material: "metal.painted:1A1A1E"), Xform(translation: V3(0, cy0, cz)))
        for k in 0..<15 {
            let a = (Float(k) - 7) * 11.5
            let r: Float = 0.128
            FA.box(&m, V3(0.018, r, 0.012), V3(sin(a * .pi / 180) * r / 2, cy0 + cos(a * .pi / 180) * r / 2 + 0.01, cz + 0.016), gilt, r: 0.003, rot: FA.q(-a, FA.Z))
        }
        FA.cylZ(&m, r: 0.035, h: 0.02, at: V3(0, cy0 + 0.015, cz + 0.012), "metal.brass-aged", bevel: 0.006, segments: 18)
        m.add(Prim.lathe([V2(0, 0), V2(0.02, 0.008), V2(0.012, 0.03), V2(0.006, 0.06), V2(0, 0.075)], segments: 12, seamTile: 0.2, material: "metal.brass-aged"), Xform(translation: V3(0, cy0 + 0.15, cz)))
        // Bulb chases: top and bottom of the fascia and up the front corners; a few burnt out.
        FG.lamps(&m, from: V3(-W / 2 + 0.1, fh - 0.025, D + 0.003), to: V3(W / 2 - 0.1, fh - 0.025, D + 0.003), count: 33, r: 0.017, dead: [7, 21, 22])
        FG.lamps(&m, from: V3(-W / 2 + 0.1, 0.03, D + 0.003), to: V3(W / 2 - 0.1, 0.03, D + 0.003), count: 33, r: 0.017, dead: [14])
        for sx: Float in [-1, 1] { FG.lamps(&m, from: V3(sx * (W / 2 - 0.05), 0.14, D + 0.003), to: V3(sx * (W / 2 - 0.05), fh - 0.14, D + 0.003), count: 5, r: 0.016) }
        // Four tie rods from eye plates high on the wall to the cornice, with turnbuckles.
        for x: Float in [-1.55, -0.6, 0.6, 1.55] {
            let a = V3(x, fh + 0.3, 0.012), b = V3(x, fh + 0.1, D - 0.1)
            FA.rod(&m, a, b, r: 0.011, "metal.galvanized-aged", sides: 8)
            let mid = a + (b - a) * 0.5
            FA.box(&m, V3(0.03, 0.03, 0.1), mid, "metal.galvanized", r: 0.006, rot: FA.q(-atan2(b.y - a.y, b.z - a.z) * 57.3, FA.X))
            FA.box(&m, V3(0.08, 0.08, 0.012), V3(x, fh + 0.3, 0.006), "metal.galvanized", r: 0.003)
            hexBolt(&m, at: V3(x, fh + 0.3, 0.012), normal: FA.Z, size: 0.016, material: "metal.rust")
            FA.cylZ(&m, r: 0.016, h: 0.01, at: V3(x, fh + 0.095, D - 0.1), "metal.stainless", bevel: 0.002, segments: 10)
        }
        // Weathering: rust runs under bulbs on the face, soot on the soffit.
        for _ in 0..<10 {
            let len = rng.float(0.05...0.2)
            FG.flat(&m, V3(rng.float(0.006...0.016), len, 0.0008), V3(rng.float(-1.9...1.9), fh - 0.04 - len / 2, ez + 0.008), "metal.rust-grime")
        }
        for _ in 0..<5 {
            FG.flat(&m, V3(rng.float(0.2...0.5), 0.0008, rng.float(0.2...0.4)), V3(rng.float(-1.8...1.8), -0.0004, rng.float(0.1...1.2)), "paint.stucco:8E8672")
        }
        groundAO(&m, height: 0.2, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
