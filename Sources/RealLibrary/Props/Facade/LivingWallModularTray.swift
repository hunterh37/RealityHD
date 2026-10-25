import simd
import Foundation

/// Living wall modular tray: 600 x 600 mm powder-coated steel cassette, 200 mm deep with 10 mm front return and a
/// 40 mm irrigation gutter along the base, hung on an aluminium Z-rail. Six double-layer needle-punched felt pockets
/// hand-stitched along their lips, each with a compost bed, hosta and trailing pothos, and a 16 mm polyethylene
/// drip line with pressure-compensating drippers fed from a riser. Mineral scale rings the drippers and the lower
/// felt is stained green.
public struct LivingWallModularTray: RealAsset {
    public static let id = "living-wall-modular-tray"
    public static let summary = "Steel living wall cassette: stitched felt pockets, drip irrigation, Z-rail hanger, hosta and trailing foliage."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 1.1)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.6, 0.6, 0.2)
    /// Powder-coated steel cassette.
    public var steel: MaterialKey = "metal.powdercoat:44484B"
    /// Felt.
    public var felt: MaterialKey = "fabric.canvas:66695C"
    public var hose: MaterialKey = "rubber.tubing"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.6, H: Float = 0.6, D: Float = 0.2, t: Float = 0.002
        // Cassette: back plate, four 1.5 mm walls, 10 mm front returns, gutter, drain slots.
        FA.box(&m, V3(W, H, t), V3(0, H / 2, t / 2), steel, r: 0.0006)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(t, H, D), V3(s * (W / 2 - t / 2), H / 2, D / 2), steel, r: 0.0006)
            FA.box(&m, V3(0.012, H - 0.004, t), V3(s * (W / 2 - 0.006), H / 2, D - t / 2), steel, r: 0.0006)
        }
        FA.box(&m, V3(W - 0.004, t, D), V3(0, H - t / 2, D / 2), steel, r: 0.0006)
        FA.box(&m, V3(W - 0.004, t, D), V3(0, t / 2, D / 2), steel, r: 0.0006)
        FA.box(&m, V3(W - 0.004, 0.012, t), V3(0, H - 0.006, D - t / 2), steel, r: 0.0006)
        FA.box(&m, V3(W - 0.004, 0.04, t), V3(0, 0.02, D - t / 2), steel, r: 0.0006)   // gutter front, 40 mm
        for k in 0..<6 {
            FC.slab(&m, V3(0.03, 0.005, 0.0012), V3(-0.25 + Float(k) * 0.1, 0.03, 0.0035), "wood.charred")
        }
        // Hanging Z-rail behind the back plate with countersunk screws.
        FA.box(&m, V3(0.5, 0.045, 0.012), V3(0, 0.45, -0.006), "metal.aluminum-brushed", r: 0.0012)
        for x: Float in [-0.2, 0, 0.2] { rivet(&m, at: V3(x, 0.45, -0.012), normal: V3(0, 0, -1), radius: 0.004, height: 0.0025, segments: 8, material: "metal.screw-zinc") }
        // Irrigation riser and three drip rows.
        let rows: [Float] = [0.115, 0.255, 0.395]
        FA.rod(&m, V3(-0.285, 0.04, 0.026), V3(-0.285, 0.57, 0.026), r: 0.0085, hose, sides: 10)
        for (i, ry) in rows.enumerated() {
            let y = ry + 0.076
            FA.rod(&m, V3(-0.285, y, 0.026), V3(0.285, y, 0.026), r: 0.008, hose, sides: 10)
            FA.box(&m, V3(0.024, 0.02, 0.024), V3(-0.285, y, 0.026), "plastic.black", r: 0.003)   // tee
            for x: Float in [-0.14, 0.14] {
                FA.rod(&m, V3(x, y - 0.006, 0.03), V3(x, y - 0.03, 0.05), r: 0.0018, "plastic.black", sides: 6)
                FA.cylZ(&m, r: 0.0045, h: 0.014, at: V3(x, y, 0.03), "plastic.black", bevel: 0.001, segments: 8)
                FC.slab(&m, V3(0.01, 0.008, 0.0005), V3(x, y - 0.012, 0.0455), "plastic.white")   // scale
            }
            _ = i
            // Pockets: two per row.
            for x: Float in [-0.14, 0.14] {
                let cx = x + rng.float(-0.003...0.003), cy = ry
                m.add(Prim.superellipsoid(V3(0.26, 0.14, 0.11), exponent: 2.8, subdivisions: 6, material: felt),
                      Xform(translation: V3(cx, cy, 0.075 + rng.float(-0.002...0.002))))
                m.add(Prim.superellipsoid(V3(0.23, 0.02, 0.075), exponent: 5, subdivisions: 4, material: "soil.potting"),
                      Xform(translation: V3(cx, cy + 0.068, 0.085)))
                let lip = (0...8).map { V3(cx - 0.115 + Float($0) * 0.0288, cy + 0.07, 0.13 - 0.0012 * Float(abs($0 - 4))) }
                m.add(stitches(along: lip, normal: { _ in V3(0, 0.6, 0.8) }, pitch: 0.006, thread: 0.0008, material: "thread.white"))
                // Planting.
                for k in 0..<8 {
                    let px = cx + rng.float(-0.09...0.09)
                    FC.leafCard(&m, "leaf.willow", at: V3(px, cy + 0.07, 0.09 + rng.float(-0.02...0.02)), width: 0.13, height: rng.float(0.5...1.0) * max(0.06, min(0.2, 0.592 - (cy + 0.07))),
                                spin: rng.float(-25...25), tilt: rng.float(-35...(-5)), yaw: rng.float(-35...35))
                    _ = k
                }
                for _ in 0..<6 {
                    FC.leafCard(&m, "leaf.boxwood", at: V3(cx + rng.float(-0.1...0.1), cy + 0.03, 0.128), width: 0.07, height: rng.float(0.07...0.14), spin: 180, tilt: rng.float(-10...(-3)))
                }
            }
        }
        // Wear: algae-stained lower felt, water streaks down the back plate, chipped coating at the front corners.
        for x: Float in [-0.14, 0.14] {
            FC.slab(&m, V3(0.2, 0.05, 0.0006), V3(x, 0.115, 0.131), "moss.cushion")
        }
        for _ in 0..<6 {
            FC.slab(&m, V3(rng.float(0.004...0.012), rng.float(0.05...0.18), 0.0005), V3(rng.float(-0.27...0.27), rng.float(0.1...0.5), 0.0028), "metal.rust:8A5A3A")
        }
        for (x, y) in [(Float(-0.294), Float(0.598)), (0.294, 0.598), (-0.294, 0.003), (0.294, 0.003)] {
            FA.box(&m, V3(0.006, 0.006, 0.0025), V3(x, y - 0.0, D - 0.001), "metal.rust", r: 0.0006)
        }
        groundAO(&m, height: 0.3, floor: 0.75)
        return LODModel(FC.fit(m, size))
    }
}
