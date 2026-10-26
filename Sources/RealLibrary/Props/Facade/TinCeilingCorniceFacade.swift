import simd
import Foundation

/// American Commercial stamped tin cornice, 2.0 x 0.5 x 0.4 m, in the style of a pressed-tin ceiling cornice carried onto a
/// storefront: a flat embossed frieze with rosettes, a cove bed mould, a dentil band, an egg-and-dart ovolo, scroll modillions
/// under a projecting corona and a cyma crown. Three 610 mm sheets meet at crimped standing seams; nail heads run along the
/// flanges over a wood nailer. Cream paint flakes to galvanized tin and rust bleeds from the nails. Base on y = 0.
public struct TinCeilingCorniceFacade: RealAsset {
    public static let id = "tin-ceiling-cornice-facade"
    public static let summary = "American Commercial pressed tin cornice, 2.0 x 0.5 m: stamped crown, egg-and-dart, dentils, modillions, crimped seams, nail heads, wood backing."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: -8, distance: 2.4)

    /// Run length in meters.
    public var length: Float = 2.0
    /// Cream paint over the tin.
    public var paint: MaterialKey = "metal.painted:CFC8B4"
    /// Bare galvanized tin where the paint is gone.
    public var tin: MaterialKey = "metal.galvanized-aged"
    public var rust: MaterialKey = "metal.rust"
    public var brass: MaterialKey = "metal.brass-aged"
    public var wood: MaterialKey = "wood.trim-weathered"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length
        let k: Float = 0.9
        // Crown profile (x out from the wall, y up), scaled so the corona stops at 0.36 m.
        let raw: [V2] = [V2(0, 0), V2(0.03, 0), V2(0.03, 0.12), V2(0.045, 0.13), V2(0.075, 0.155), V2(0.1, 0.2), V2(0.1, 0.27), V2(0.115, 0.28),
                         V2(0.13, 0.3), V2(0.15, 0.33), V2(0.15, 0.34), V2(0.36, 0.34), V2(0.36, 0.4), V2(0.39, 0.41), V2(0.4, 0.43), V2(0.38, 0.47),
                         V2(0.3, 0.5), V2(0, 0.5)]
        let prof = raw.map { V2($0.x * k, $0.y) }
        // Three sheets, each repainted at a different date (slightly different cream), 610 mm in the middle.
        let sheets: [(Float, Float, MaterialKey)] = [(-L / 2, -0.305, "metal.painted:C7BFA9"), (-0.305, 0.305, paint), (0.305, L / 2, "metal.painted:BFB59C")]
        for (a, b, mat) in sheets { FA.run(&m, prof, length: b - a - 0.002, at: V3((a + b) / 2, 0, 0), mat, bevel: 0.002) }

        // Wood nailer behind the sheets, two rails with a visible end grain and nails.
        for y: Float in [0.07, 0.43] {
            FA.box(&m, V3(L - 0.02, 0.06, 0.04), V3(0, y, -0.02), wood, r: 0.003)
        }

        // Dentil band: 20 x 25 mm blocks at 40 mm pitch, skipping the modillion stations.
        let mod: [Float] = (0..<8).map { -0.875 + Float($0) * 0.25 }
        var x: Float = -L / 2 + 0.03
        while x < L / 2 - 0.02 {
            if !mod.contains(where: { abs($0 - x) < 0.04 }) {
                FO8.slab(&m, 0.02, 0.05, 0.016, V3(x, 0.235, 0.1 * k + 0.008), paint, bevel: 0.0015)
            }
            x += 0.04
        }
        // Scroll modillions under the corona (a bracket profile extruded 40 mm wide).
        let bracket: [V2] = [V2(0.092, 0.2), V2(0.115, 0.2), V2(0.19, 0.236), V2(0.26, 0.285), V2(0.31, 0.318), V2(0.324, 0.32), V2(0.324, 0.34), V2(0.092, 0.34)]
        for mx in mod {
            m.add(Prim.extrude(bracket, depth: 0.04, bevel: 0.0025, bevelSegments: 1, material: paint),
                  Xform(translation: V3(mx, 0, 0), rotation: FA.q(-90, FA.Y)))
            // Acanthus-style leaf boss on the bracket front.
            m.add(Prim.superellipsoid(V3(0.03, 0.028, 0.02), exponent: 2, subdivisions: 3, material: paint), Xform(translation: V3(mx, 0.248, 0.168)))
        }

        // Egg-and-dart on the ovolo: ovoid eggs with darts between, 50 mm pitch.
        var e = 0
        x = -L / 2 + 0.05
        while x < L / 2 - 0.03 {
            m.add(Prim.superellipsoid(V3(0.02, 0.036, 0.018), exponent: 2, subdivisions: 2, material: paint), Xform(translation: V3(x, 0.302, 0.121)))
            m.add(Prim.extrude([V2(0, -0.015), V2(0.007, 0), V2(0, 0.015), V2(-0.007, 0)], depth: 0.008, bevel: 0.001, bevelSegments: 1, material: paint),
                  Xform(translation: V3(x + 0.025, 0.302, 0.113)))
            x += 0.05
            e += 1
        }

        // Frieze: embossed raised border panels and brass-centred rosettes, one per 250 mm.
        for s in [-1, 1] as [Float] {
            FO8.slab(&m, 0.58, 0.012, 0.008, V3(s * 0.31 + (s > 0 ? 0.3 : -0.3) * 0, 0.108, 0.036), paint, bevel: 0.0015)
        }
        FO8.slab(&m, L - 0.06, 0.012, 0.008, V3(0, 0.1, 0.0345), paint, bevel: 0.0015)
        FO8.slab(&m, L - 0.06, 0.012, 0.008, V3(0, 0.02, 0.0345), paint, bevel: 0.0015)
        var rx: Float = -L / 2 + 0.15
        while rx < L / 2 - 0.1 {
            FA.cylZ(&m, r: 0.034, h: 0.008, at: V3(rx, 0.06, 0.03), paint, bevel: 0.0015, segments: 16)
            m.add(Prim.torus(major: 0.022, minor: 0.004, segments: 14, sides: 5, material: paint), Xform(translation: V3(rx, 0.06, 0.04), rotation: FA.q(90, FA.X)))
            FC.bead(&m, r: 0.009, at: V3(rx, 0.06, 0.042), brass, sub: 3)
            for p in 0..<5 {
                let a = Float(p) / 5 * 2 * .pi
                FC.bead(&m, r: 0.004, at: V3(rx + 0.027 * cos(a), 0.06 + 0.027 * sin(a), 0.039), paint, sub: 1)
            }
            rx += 0.25
        }

        // Crimped standing seams where the 610 mm sheets overlap: a strap following the whole profile.
        for sx: Float in [-0.305, 0.305] {
            let off = Shape2D.offset(prof, 0.003)
            m.add(Prim.extrude(off, depth: 0.018, bevel: 0.0015, bevelSegments: 1, material: paint),
                  Xform(translation: V3(sx + rng.float(-0.004...0.004), 0, 0), rotation: FA.q(-90, FA.Y)))
        }

        // Nail heads along the lower and upper frieze flanges and along the crown's top edge.
        let top = V3(0, 0.5 - 0.0, 0)
        _ = top
        for y: Float in [0.012, 0.114] {
            var nx: Float = -L / 2 + 0.04
            while nx < L / 2 - 0.03 {
                rivet(&m, at: V3(nx, y, 0.0392), normal: FA.Z, radius: 0.0046, segments: 6, material: tin)
                nx += 0.08
            }
        }
        // Rust bleeding from selected nails and seams, paint loss patches showing galvanized tin, a dented corona.
        for _ in 0..<10 {
            let nx = rng.float(-L / 2 + 0.1...L / 2 - 0.1)
            FO8.slab(&m, rng.float(0.006...0.014), rng.float(0.04...0.09), 0.0014, V3(nx, 0.065, 0.0398), rust, bevel: 0.0004)
        }
        for _ in 0..<12 {
            let nx = rng.float(-L / 2 + 0.1...L / 2 - 0.1)
            let ys: [Float] = [0.24, 0.30, 0.37]
            let yy = ys[rng.int(0...2)]
            let zz: Float = yy < 0.33 ? 0.124 : 0.325
            FO8.slab(&m, rng.float(0.02...0.06), rng.float(0.01...0.026), 0.0016, V3(nx, yy + 0.0, zz), rng.chance(0.4) ? tin : rust, bevel: 0.0004)
        }

        // Soot on the soffit between the modillions and a dirt line under the corona drip.
        for mx in mod.dropLast() {
            FA.box(&m, V3(0.17, 0.002, 0.2), V3(mx + 0.125, 0.3385, 0.24), "metal.painted:5E574A", r: 0.0006)
        }
        FA.box(&m, V3(L - 0.04, 0.012, 0.002), V3(0, 0.334, 0.324 + 0.0), "metal.painted:6A6354", r: 0.0006)

        // Mitred end returns with a closing block.
        for en: Float in [-1, 1] {
            m.add(Prim.extrude(prof, depth: 0.004, bevel: 0.001, bevelSegments: 1, material: paint),
                  Xform(translation: V3(en * (L / 2 + 0.002), 0, 0), rotation: FA.q(-90, FA.Y)))
        }

        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
