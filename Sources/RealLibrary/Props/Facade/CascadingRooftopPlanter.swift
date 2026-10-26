import simd
import Foundation

/// Cascading rooftop planter: three 660 mm Corten steel troughs stepped 340, 500 and 660 mm high. 4 mm plate with a
/// folded 25 mm top return, ground continuous corner welds, 60 mm plinth rails, drain slots, bolted gusset
/// straps tying the tiers together, mulched soil and ornamental grass. Rain run-off stains the lower plates.
public struct CascadingRooftopPlanter: RealAsset {
    public static let id = "cascading-rooftop-planter"
    public static let summary = "Three-tier stepped Corten steel planter: welded plate troughs, folded lips, drain slots, bolted ties, ornamental grasses."
    public static let tags = ["prop", "architecture", "facade", "metal", "decor"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 2.4)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 1.0, 0.6)
    /// Weathering steel plate.
    public var corten: MaterialKey = "metal.corten:8A4A2F"
    /// Bright ground weld beads and bolt heads.
    public var steel: MaterialKey = "metal.steel"
    public var grass: MaterialKey = "leaf.river-cane"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let t: Float = 0.004, D: Float = 0.6, w: Float = 0.66, plinth: Float = 0.06
        let heights: [Float] = [0.34, 0.50, 0.66]
        for (i, H) in heights.enumerated() {
            let cx = (Float(i) - 1) * (w + 0.01), hy = H - plinth
            let wearMat: MaterialKey = i == 0 ? "metal.rust" : corten
            // Plinth rails (60 x 40 flat bar on edge) and floor.
            for z: Float in [0.1, D - 0.1] {
                FA.box(&m, V3(w - 0.1, plinth, 0.04), V3(cx, plinth / 2, z), steel, r: 0.002)
            }
            FA.box(&m, V3(w, t, D), V3(cx, plinth + t / 2, D / 2), corten, r: 0.001)
            // Wall plates (front and back full width, ends fit between).
            FA.box(&m, V3(w, hy, t), V3(cx, plinth + hy / 2, D - t / 2), i == 0 ? wearMat : corten, r: 0.0012)
            FA.box(&m, V3(w, hy, t), V3(cx, plinth + hy / 2, t / 2), corten, r: 0.0012)
            for s: Float in [-1, 1] {
                FA.box(&m, V3(t, hy, D - 2 * t), V3(cx + s * (w / 2 - t / 2), plinth + hy / 2, D / 2), corten, r: 0.0012)
            }
            // Folded return: 25 mm lip turned inward on all four sides, 4 mm thick.
            FA.box(&m, V3(w - 0.002, t, 0.025), V3(cx, H - t / 2, D - 0.0125), corten, r: 0.001)
            FA.box(&m, V3(w - 0.002, t, 0.025), V3(cx, H - t / 2, 0.0125), corten, r: 0.001)
            for s: Float in [-1, 1] {
                FA.box(&m, V3(0.025, t, D - 0.05), V3(cx + s * (w / 2 - 0.0125), H - t / 2, D / 2), corten, r: 0.001)
            }
            // Outward top flange (20 mm) turned over a 6 mm radius, and butt-weld seams on the front and back sheets.
            FA.box(&m, V3(w + 0.004, 0.006, 0.02), V3(cx, H - 0.003, D + 0.006), corten, r: 0.002)
            FA.box(&m, V3(w + 0.004, 0.006, 0.02), V3(cx, H - 0.003, -0.006), corten, r: 0.002)
            for s: Float in [-1, 1] {
                FA.box(&m, V3(0.02, 0.006, D + 0.02), V3(cx + s * (w / 2 + 0.004), H - 0.003, D / 2), corten, r: 0.002)
            }
            for z: Float in [0, D] {
                m.add(Prim.cylinder(radius: 0.0032, height: hy, bevel: 0.0008, segments: 6, bevelSegments: 1, material: "metal.corten:5A2E1E"),
                      Xform(translation: V3(cx + 0.1, plinth, z + (z == 0 ? -0.0008 : 0.0008))))
            }
            // Ground weld beads on the four vertical corners (bright steel, slightly proud).
            for sx: Float in [-1, 1] {
                for z: Float in [0.0, D] {
                    m.add(Prim.cylinder(radius: 0.0034, height: hy, bevel: 0.0008, segments: 6, bevelSegments: 1, material: steel),
                          Xform(translation: V3(cx + sx * (w / 2), plinth, z)))
                }
            }
            // Drain slots (5 x 40 mm) low on the front plate.
            for k in 0..<3 {
                FA.box(&m, V3(0.045, 0.008, 0.0012), V3(cx + (Float(k) - 1) * 0.16, plinth + 0.03, D + 0.0003), "wood.charred", r: 0.0003)
            }
            // Soil and mulch.
            m.add(Prim.superellipsoid(V3(w - 0.07, 0.12, D - 0.07), exponent: 7, subdivisions: 6, material: "soil.potting"),
                  Xform(translation: V3(cx, H - 0.025 - 0.06 + 0.06 - 0.02, D / 2)))
            // Grass clumps: crossed leaf cards, taller on the higher tiers.
            let n = 17
            for k in 0..<n {
                let gx = cx + rng.float(-(w / 2 - 0.12)...(w / 2 - 0.12)), gz = D / 2 + rng.float(-0.17...0.17)
                let hgt = rng.float(0.22...0.32) + Float(i) * 0.1
                FC.leafCard(&m, grass, at: V3(gx, H - 0.06, gz), width: hgt * 0.8, height: hgt, spin: rng.float(-8...8), tilt: rng.float(-6...6), yaw: Float(k) * 63)
                FC.leafCard(&m, grass, at: V3(gx, H - 0.06, gz), width: hgt * 0.8, height: hgt * 0.92, spin: rng.float(-8...8), tilt: rng.float(-6...6), yaw: Float(k) * 63 + 90)
            }
        }
        // Gusset straps (60 x 6 flat bar) bolting adjacent troughs together front and back, with hex bolts.
        for i in 0..<2 {
            let bx = (Float(i) - 0.5) * (w + 0.01)
            for z: Float in [D + 0.0, 0.0] {
                let lo = heights[i], zz = z == 0 ? -0.003 : D + 0.003
                FA.box(&m, V3(0.12, 0.06, 0.006), V3(bx, lo - 0.1, zz), steel, r: 0.0015)
                for dx: Float in [-0.042, 0.042] {
                    hexBolt(&m, at: V3(bx + dx, lo - 0.1, zz + (z == 0 ? -0.003 : 0.003)), normal: V3(0, 0, z == 0 ? -1 : 1), size: 0.014, material: steel)
                }
            }
        }
        // Wear: rust-bloom run-off streaks below the lips and at the weld beads.
        for (i, H) in heights.enumerated() {
            let cx = (Float(i) - 1) * (w + 0.01)
            for _ in 0..<5 {
                let len = rng.float(0.05...0.16)
                FC.slab(&m, V3(rng.float(0.01...0.03), len, 0.0006), V3(cx + rng.float(-0.28...0.28), H - len / 2 - 0.006, D + 0.0004), "metal.rust:B5683F")
            }
            // Mud splash band and moss along the foot of the front plate, lime-scale bloom under the drain slots.
            FC.slab(&m, V3(w - 0.01, 0.055, 0.0008), V3(cx, 0.06 + 0.0275, D + 0.0005), "soil.potting")
            for _ in 0..<3 {
                m.add(Prim.superellipsoid(V3(rng.float(0.05...0.09), 0.012, 0.03), exponent: 2.2, subdivisions: 2, material: "moss.cushion"),
                      Xform(translation: V3(cx + rng.float(-0.28...0.28), 0.064, D + 0.004)))
            }
        }
        groundAO(&m, height: 0.3, floor: 0.7)
        return LODModel(FC.fit(m, size))
    }
}
