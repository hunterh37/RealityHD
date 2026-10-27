import simd
import Foundation

/// Deli meat pack: 20 cm wide, 3 cm tall, 15 cm deep vacuum pack of sliced ham, film shrunk tight over a stack of fanned slices with
/// fat rims, crimped serrated seals on both short ends, film wrinkles, a printed card label, a price sticker and fogged condensation.
public struct DeliMeatPack: RealAsset {
    public static let id = "deli-meat-pack"
    public static let summary = "Vacuum-packed sliced ham, 20 cm: shrunk film with wrinkles, fanned slices with fat rim, crimped seals, label, sticker."
    public static let tags = ["prop", "interior", "pantry", "plastic", "paper", "food"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: -30, elevation: 38, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.20, 0.03, 0.15)
    /// Film, meat, fat and label colour keys.
    public var film: MaterialKey = "plastic.clear"
    public var meat: MaterialKey = "food.cream:D98C8C"
    public var fat: MaterialKey = "food.cream:F3DCCB"
    public var label: MaterialKey = "plastic.white:F4F1E8"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sx: Float = 0.148, sz: Float = 0.150, top: Float = 0.026
        // Cardboard backing board under the slices.
        m.add(Prim.roundedBox(V3(sx - 0.004, 0.0016, sz - 0.008), radius: 0.0005, bevelSegments: 1, material: "paper.screwbox-kraft"), Xform(translation: V3(0, 0.0008, 0)))
        // Fanned slices: each slice a thin oval slab with a fat rim, offset and rotated slightly.
        let n = 8
        for i in 0..<n {
            let t = Float(i)
            let y = 0.0026 + t * 0.0024
            let ox = rng.float(-0.004...0.004) + (t - 4) * 0.0012, oz = rng.float(-0.005...0.005)
            let rot = rng.float(-6...6)
            let flat = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
            let tilt = simd_quatf(degrees: rng.float(-1.2...1.2), axis: V3(1, 0, 1))
            let yaw = simd_quatf(degrees: rot, axis: .up)
            // Fat rim ring first (slightly larger), then the lean meat on top of it.
            m.add(Prim.extrude(Shape2D.superellipse(0.138, 0.121, exponent: 2.6), depth: 0.0026, bevel: 0.0009, bevelSegments: 2, material: fat),
                  Xform(translation: V3(ox, y - 0.0003, oz), rotation: yaw * tilt * flat))
            var lean = Prim.extrude(Shape2D.superellipse(0.132, 0.115, exponent: 2.6), depth: 0.0030, bevel: 0.0010, bevelSegments: 2, material: meat)
            let kk = rng.float(0...6)
            lean.displace { p, _ in 0.0003 * sin(p.x * 150 + kk) * sin(p.y * 130 + kk * 0.7) }
            m.add(lean, Xform(translation: V3(ox, y + 0.0002, oz), rotation: yaw * tilt * flat))
        }
        // Film envelope: tight upper skin shrunk over the stack with wrinkles that run toward the seals.
        var skin = Prim.superellipsoid(V3(sx + 0.006, top, sz + 0.002), exponent: 6, subdivisions: 5, material: film)
        let k0 = rng.float(0...6), k1 = rng.float(0...6)
        skin.displace { p, _ in
            let edge = min(1, abs(p.x) / 0.08)
            return 0.0016 * sin(p.z * 210 + k0) * edge * edge + 0.0007 * sin(p.x * 150 + p.z * 90 + k1)
        }
        m.add(skin, Xform(translation: V3(0, top / 2 + 0.0014, 0)))
        // Seals: flat serrated flanges at both short ends.
        for s in [Float(1), -1] {
            let fx = s * (sx / 2 + 0.0155)
            m.add(Prim.roundedBox(V3(0.0220, 0.0009, sz + 0.002), radius: 0.0003, bevelSegments: 1, material: film), Xform(translation: V3(fx, 0.0050, 0)))
            for r in 0..<14 {
                let z = -sz / 2 + 0.008 + Float(r) * ((sz - 0.016) / 13)
                m.add(Prim.roundedBox(V3(0.0120, 0.0004, 0.0016), radius: 0.0001, bevelSegments: 1, material: "plastic.frosted"),
                      Xform(translation: V3(fx, 0.0058, z)))
            }
            m.add(Prim.roundedBox(V3(0.0016, 0.0010, sz + 0.0012), radius: 0.0004, bevelSegments: 1, material: "plastic.frosted"),
                  Xform(translation: V3(s * (sx / 2 + 0.0050), 0.0050, 0)))
        }
        // Printed label card across the top: wider white block with a dark logo stripe and a nutrition grid.
        m.add(Prim.roundedBox(V3(0.100, 0.0006, 0.060), radius: 0.0002, bevelSegments: 1, material: label), Xform(translation: V3(-0.020, top + 0.0017, -0.032)))
        m.add(Prim.roundedBox(V3(0.100, 0.0008, 0.016), radius: 0.0002, bevelSegments: 1, material: "plastic.white:8C1D2C"), Xform(translation: V3(-0.020, top + 0.0022, -0.012)))
        m.add(Prim.roundedBox(V3(0.060, 0.0008, 0.0070), radius: 0.0002, bevelSegments: 1, material: "plastic.white:2A2420"), Xform(translation: V3(-0.040, top + 0.0022, -0.040)))
        m.add(Prim.roundedBox(V3(0.026, 0.0008, 0.014), radius: 0.0002, bevelSegments: 1, material: "plastic.white:E8C14A"), Xform(translation: V3(0.0, top + 0.0022, -0.044)))
        // Label text lines, weight panel and a barcode.
        for r in 0..<4 {
            m.add(Prim.roundedBox(V3(0.060 - Float(r % 2) * 0.016, 0.0006, 0.0022), radius: 0.0001, bevelSegments: 1, material: "plastic.white:2A2420"),
                  Xform(translation: V3(-0.043 - Float(r % 2) * 0.008, top + 0.0021, -0.0555 + Float(r) * 0.0055)))
        }
        for i in 0..<16 {
            m.add(Prim.roundedBox(V3(0.0008 + Float(i % 3) * 0.0005, 0.0006, 0.012), radius: 0.0001, bevelSegments: 1, material: "plastic.white:1E1B19"),
                  Xform(translation: V3(0.0105 + Float(i) * 0.0021, top + 0.0021, -0.056)))
        }
        // Price sticker with a slightly lifted corner: the story detail.
        m.add(Prim.roundedBox(V3(0.034, 0.0005, 0.022), radius: 0.0002, bevelSegments: 1, material: "plastic.white:F2D13A"), Xform(translation: V3(0.050, top + 0.0017, 0.034), rotation: simd_quatf(degrees: -8, axis: .up)))
        m.add(Prim.roundedBox(V3(0.014, 0.0004, 0.006), radius: 0.0001, bevelSegments: 1, material: "plastic.white:2A2420"), Xform(translation: V3(0.052, top + 0.0023, 0.034), rotation: simd_quatf(degrees: -8, axis: .up)))
        m.add(Prim.roundedBox(V3(0.007, 0.0004, 0.007), radius: 0.0001, bevelSegments: 1, material: "plastic.white:F2D13A"),
              Xform(translation: V3(0.0645, top + 0.0024, 0.0415), rotation: simd_quatf(degrees: -8, axis: .up) * simd_quatf(degrees: 18, axis: V3(1, 0, 0))))
        // Fog: condensation beads on the film.
        for _ in 0..<30 {
            let x = rng.float(-0.060...0.060), z = rng.float(-0.060...0.060), s = rng.float(0.0012...0.0026)
            m.add(Prim.superellipsoid(V3(s, s * 0.5, s * 1.2), exponent: 2, subdivisions: 1, material: "glass.clear"),
                  Xform(translation: V3(x, top + 0.0022 - (abs(x) / 0.1) * 0.003, z)))
        }
        DD1MPantry.grounded(&m)
        groundAO(&m)
        return LODModel(m)
    }
}
