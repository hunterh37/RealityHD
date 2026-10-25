import simd
import Foundation

/// Bat box, wall mounted: rough-sawn stained timber roost. Kerfed back board (3 mm grooves at 25 mm for footholds),
/// two 6 mm vertical baffles, raked side boards, a front panel stopping 70 mm above the bottom to leave the 30 mm
/// entrance slot over a landing ledge, sloping lid with a hemmed galvanised cap fixed by washered clout nails.
public struct BatBoxWallMounted: RealAsset {
    public static let id = "bat-box-wall-mounted"
    public static let summary = "Stained timber bat roost: kerfed back board, baffles, bottom entrance slot, raked sides, galvanised-capped lid."
    public static let tags = ["prop", "architecture", "facade", "wood", "decor"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 1.1)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.30, 0.60, 0.14)
    /// Stained board material.
    public var stain: MaterialKey = "wood.walnut-oiled"
    /// Lid and ledge material.
    public var lidWood: MaterialKey = "wood.chisel-ash-grimy"
    /// Roof cap.
    public var tin: MaterialKey = "metal.galvanized-aged"
    public var zinc: MaterialKey = "metal.screw-zinc"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let t: Float = 0.019, bodyW: Float = 0.26
        // Back board: profile (z out, y up) with kerf grooves 3 mm deep, 2 mm wide, every 25 mm from 120 to 520 mm.
        var back: [V2] = [V2(0, 0), V2(t, 0)]
        var y: Float = 0.12
        while y < 0.52 {
            back += [V2(t, y), V2(t - 0.003, y + 0.0004), V2(t - 0.003, y + 0.0024), V2(t, y + 0.0028)]
            y += 0.025
        }
        back += [V2(t, 0.6), V2(0, 0.6)]
        FA.run(&m, back, length: 0.30, stain, bevel: 0.0015)
        for x: Float in [-0.11, 0.11] {
            FA.cylZ(&m, r: 0.011, h: 0.0016, at: V3(x, 0.575, t - 0.0004), zinc, bevel: 0.0004, segments: 14)
            rivet(&m, at: V3(x, 0.575, t + 0.0012), normal: FA.Z, radius: 0.0055, height: 0.0035, material: zinc)
        }
        // Side boards raked: 560 mm at the back down to 520 mm at the front.
        let side: [V2] = [V2(t, 0.03), V2(0.14, 0.03), V2(0.14, 0.52), V2(t, 0.56)]
        for s: Float in [-1, 1] {
            FA.side(&m, side, thick: t, at: V3(s * (bodyW / 2 - t / 2), 0, 0), "wood.walnut-oiled:7A5C48", bevel: 0.0015)
            for (z, yy): (Float, Float) in [(0.035, 0.1), (0.035, 0.45), (0.125, 0.45), (0.125, 0.14)] {
                rivet(&m, at: V3(s * bodyW / 2, yy + rng.float(-0.003...0.003), z), normal: V3(s, 0, 0), radius: 0.0035, height: 0.002, material: zinc)
            }
        }
        // Front panel stops at 100 mm: slot 100...30 mm is the entrance. Landing ledge below the slot.
        FA.box(&m, V3(bodyW - 2 * t - 0.001, 0.42, t), V3(0, 0.10 + 0.21, 0.14 - t / 2), stain, r: 0.0015)
        FA.box(&m, V3(bodyW - 2 * t - 0.001, 0.016, 0.03), V3(0, 0.03 + 0.008 + 0.002, 0.14 - 0.015 - 0.01), lidWood, r: 0.002)
        // Baffles (6 mm vertical partitions) between the sides, visible through the slot.
        for z: Float in [0.05, 0.08, 0.11] {
            FA.box(&m, V3(bodyW - 2 * t - 0.002, 0.44, 0.006), V3(0, 0.07 + 0.22, z), "wood.chisel-ash-grimy", r: 0.001)
        }
        // Floor-less base: dark closure strip under the slot bottom (roost interior shadow plate).
        // Lid: board raked, 25 mm front overhang, tin cap with 20 mm hemmed drip lip.
        func lidY(_ z: Float) -> Float { 0.565 - 0.0975 * (z - 0.019) }
        let lt: Float = 0.018
        FA.run(&m, [V2(0, lidY(0)), V2(0.165, lidY(0.165)), V2(0.165, lidY(0.165) + lt), V2(0, lidY(0) + lt)], length: 0.30, lidWood, bevel: 0.0025)
        let tc: Float = lt + 0.0006
        FA.run(&m, [V2(-0.004, lidY(-0.004) + tc), V2(0.17, lidY(0.17) + tc), V2(0.17, lidY(0.17) + tc + 0.0012), V2(-0.004, lidY(-0.004) + tc + 0.0012)],
               length: 0.312, tin, bevel: 0.0004)
        FA.run(&m, [V2(0.1688, lidY(0.17) + tc + 0.0012), V2(0.17, lidY(0.17) + tc + 0.0012), V2(0.17, lidY(0.17) - 0.012), V2(0.1688, lidY(0.17) - 0.012)],
               length: 0.312, tin, bevel: 0.0004)
        for x: Float in [-0.12, -0.04, 0.04, 0.12] {
            for z: Float in [0.04, 0.145] {
                let zz = z + rng.float(-0.003...0.003), top = lidY(zz) + tc + 0.0012
                FA.cylZ(&m, r: 0.0065, h: 0.0006, at: V3(x, top + 0.0003, zz), zinc, bevel: 0.0002, segments: 12)
                m.add(Prim.superellipsoid(V3(0.011, 0.004, 0.011), exponent: 2.2, subdivisions: 3, material: zinc), Xform(translation: V3(x, top + 0.0015, zz)))
                if rng.chance(0.55) {   // rust bloom around a nail head
                    m.add(Prim.superellipsoid(V3(0.02, 0.0015, 0.016), exponent: 2, subdivisions: 3, material: "metal.rust"), Xform(translation: V3(x, top + 0.0004, zz)))
                }
            }
        }
        // Rust run from the front nails down the hemmed lip.
        FA.run(&m, [V2(0.1712, lidY(0.17) - 0.002), V2(0.1718, lidY(0.17) - 0.002), V2(0.1718, lidY(0.17) - 0.012), V2(0.1712, lidY(0.17) - 0.012)],
               length: 0.012, "metal.rust", bevel: 0.0001)
        // Weathering: sun-bleached grey streaks below the lid overhang, a drying check in the front panel,
        // grime tide line along the base, and a rust-stained clout nail run.
        for i in 0..<6 {
            let x = -0.1 + Float(i) * 0.04 + rng.float(-0.006...0.006), len = rng.float(0.08...0.26)
            FA.box(&m, V3(rng.float(0.003...0.007), len, 0.0004), V3(x, 0.52 - len / 2 - 0.002, 0.14 + 0.0001), "wood.walnut-oiled:5C564F", r: 0.0002)
        }
        FA.box(&m, V3(0.0016, 0.17, 0.0004), V3(-0.045, 0.36, 0.14 + 0.0001), "wood.charred", r: 0.0005)
        FA.box(&m, V3(0.0012, 0.07, 0.0004), V3(0.072, 0.17, 0.14 + 0.0001), "wood.charred", r: 0.0005)
        FA.box(&m, V3(bodyW - 2 * t - 0.002, 0.025, 0.0004), V3(0, 0.1125, 0.14 + 0.0001), "wood.walnut-oiled:2B2420", r: 0.0005)
        // Guano splashes on the landing ledge and moss in the tin cap's back valley.
        for i in 0..<6 {
            let x = rng.float(-0.1...0.1), z = rng.float(0.115...0.135)
            m.add(Prim.superellipsoid(V3(rng.float(0.006...0.014), 0.0012, rng.float(0.005...0.01)), exponent: 2, subdivisions: 3, material: "plastic.white"),
                  Xform(translation: V3(x, 0.0475 + 0.0003, z)))
            _ = i
        }
        for x: Float in [-0.1, -0.035, 0.07, 0.12] {
            let w = rng.float(0.03...0.05)
            m.add(Prim.superellipsoid(V3(w, 0.012, w * 0.6), exponent: 2.2, subdivisions: 4, material: "moss.cushion"),
                  Xform(translation: V3(x, lidY(0.01) + tc + 0.0012 + 0.003, 0.012)))
        }
        groundAO(&m, height: 0.2, floor: 0.7)
        return LODModel(FC.fit(m, size))
    }
}
