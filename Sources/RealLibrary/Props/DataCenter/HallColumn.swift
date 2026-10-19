import simd
import Foundation

/// Hall column: Worn cast-in-place concrete data-center hall column, parametric height, form-tie cone holes in grid, grout pad, scuffed yellow guard. Parts: cast concrete column, yellow-black hazard impact guard, steel anchor plate with bolts, form-tie marks, chamfered edges.
public struct HallColumn: RealAsset {
    public static let id = "hall-column"
    public static let summary = "Parametric concrete hall column with hazard impact guard, anchor plate and form-tie marks."
    public static let tags = ["prop"]
    public static let budget = 800
    public static let author = "realityhd"

    /// Column height in meters (width and depth fixed at 0.6).
    public var height: Float = 3.2
    /// Impact guard height in meters.
    public var guardHeight: Float = 1.2
    /// Column concrete.
    public var concrete: MaterialKey = "concrete.smooth:9A9892"
    /// Guard paint.
    public var guardPaint: MaterialKey = "metal.powdercoat:E3B81A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        func rnd() -> Float { Float(rng.next() % 1000) / 1000 }
        func box(_ s: V3, _ c: V3, r: Float = 0, mat: MaterialKey) {
            if r == 0 { m.add(cuboid(s, material: mat), Xform(translation: c)); return }
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        let w: Float = 0.6, h = height
        let plate: Float = 0.03, grout: Float = 0.025
        // Grout pad, anchor plate, four hex nuts with washers and bolt tails.
        box(V3(0.62, grout, 0.62), V3(0, grout / 2, 0), mat: "concrete.rough:84817B")
        box(V3(0.6, plate, 0.6), V3(0, grout + plate / 2, 0), mat: "metal.galvanized-aged")
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let c = V3(sx * 0.272, grout + plate, sz * 0.272)
            m.add(Prim.cylinder(radius: 0.026, height: 0.04, bevel: 0.002, segments: 6, bevelSegments: 1, material: "metal.galvanized-aged"), Xform(translation: c))
        } }
        // Shaft with chamfered arrises, sits on the plate.
        let y0 = grout + plate + 0.08
        let shaftW = w - 0.0
        m.add(Prim.roundedBox(V3(shaftW - 0.1, h - y0, shaftW - 0.1), radius: 0.02, bevelSegments: 1, material: concrete), Xform(translation: V3(0, y0 + (h - y0) / 2, 0)))
        // Pour-lift cold joint and a patched honeycomb near the base.
        box(V3(w - 0.098, 0.006, w - 0.098), V3(0, y0 + 1.82, 0), mat: "concrete.rough:6E6B66")
        box(V3(0.12, 0.09, 0.006), V3(0.12, y0 + 1.45, (w - 0.1) / 2 + 0.001), mat: "concrete.rough:B3B0A8")
        // Form-tie cone holes: grid of dark dimples on all faces above the guard.
        let half = (w - 0.1) / 2
        for row in 0..<2 {
            let y = y0 + guardHeight + 0.45 + Float(row) * 0.6
            if y > h - 0.2 { continue }
            for off: Float in [0.12] {
                for f in 0..<4 {
                    let ax = Float(f) * .pi / 2
                    let (c, s) = (cos(ax), sin(ax))
                    let loc = V3(off, 0, half + 0.001)
                    let p = V3(loc.x * c + loc.z * s, y, -loc.x * s + loc.z * c)
                    let sz = f % 2 == 0 ? V3(0.05, 0.05, 0.006) : V3(0.006, 0.05, 0.05)
                    box(sz, p, mat: "plastic.matte:2A2926")
                }
            }
        }
        // Rust bleed under one tie.
        box(V3(0.012, 0.22, 0.003), V3(-0.12, y0 + guardHeight + 0.34, half + 0.0015), mat: "concrete.rough:7A5E4A")
        // Impact guard: yellow steel sleeve, black hazard bands, top cap lip, scuffs and a dent.
        let gw = w - 0.04
        box(V3(gw, guardHeight, gw), V3(0, y0 + guardHeight / 2, 0), r: 0.02, mat: guardPaint)
        let bands = 4
        for k in 0..<bands {
            let y = y0 + 0.12 + Float(k) * (guardHeight - 0.24) / Float(bands - 1)
            box(V3(gw + 0.006, 0.09, gw + 0.006), V3(0, y, 0), mat: "plastic.matte:1A1A1A")
        }
        box(V3(gw + 0.02, 0.025, gw + 0.02), V3(0, y0 + guardHeight + 0.0125, 0), mat: "metal.galvanized-aged")
        box(V3(0.22, 0.02, 0.004), V3(0.05, y0 + 0.62, gw / 2 + 0.003), mat: "metal.powdercoat:6A6B6E")
        box(V3(0.004, 0.18, 0.14), V3(gw / 2 + 0.003, y0 + 0.45 + rnd() * 0.1, -0.06), mat: "metal.powdercoat:5A5446")
        box(V3(0.004, 0.012, 0.3), V3(-gw / 2 - 0.003, y0 + 0.2, 0.0), mat: "metal.powdercoat:C9A21A")
        groundAO(&m, height: 0.15, floor: 0)
        return LODModel(m)
    }
}
