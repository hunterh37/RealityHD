import simd
import Foundation

/// Rice cooker: white round body on a black base ring, hinged domed lid with steam vent and latch
/// button, side handles, front control with a cook lever and two indicator lamps, a rice scoop clipped
/// to the body.
public struct RiceCooker: RealAsset {
    public static let id = "rice-cooker"
    public static let summary = "Rice cooker: white body, domed hinged lid with steam vent and latch, side handles, cook lever and lamps."
    public static let tags = ["prop", "interior", "kitchen", "plastic", "appliance"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth) including handles and front panel.
    public var size = V3(0.28, 0.23, 0.28)
    /// Body material.
    public var body: MaterialKey = "plastic.white"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias K = DD1DKitchen
        let foot: Float = 0.010
        let R: Float = 0.12
        _ = rng.float()
        let gray: MaterialKey = "plastic.matte:8A8C90"
        K.feet(&m, w: 0.2, d: 0.2, inset: 0.02, h: foot, r: 0.011)
        // Black base ring, white body with slight belly, rolled upper rim.
        K.lathe(&m, [(0, foot), (0.105, foot), (0.11, foot + 0.004), (0.113, foot + 0.02), (0.1135, foot + 0.026), (0, foot + 0.026)], at: .zero, "plastic.black", seg: 44)
        K.lathe(&m, [(0.113, foot + 0.026), (0.12, foot + 0.04), (R, 0.1), (0.118, 0.14), (0.113, 0.152), (0.109, 0.1545), (0.103, 0.152), (0.1, 0.15)], at: .zero, body, seg: 48)
        K.seam(&m, V3(0.0016, 0.0016, 0.0016), .zero)
        m.add(Prim.torus(major: 0.1165, minor: 0.0013, segments: 48, sides: 6, material: K.dark), Xform(translation: V3(0, foot + 0.0275, 0)))
        // Wear: yellowed rim band, rice starch crust under the lid edge, scuffed black base ring.
        m.add(Prim.torus(major: 0.1135, minor: 0.0035, segments: 48, sides: 6, material: "plastic.matte:D8C99A"), Xform(translation: V3(0, 0.1535, 0)))
        K.cyl(&m, r: 0.0125, h: 0.002, at: V3(0.04, 0.1545, 0.105), "plastic.matte:E6DDBE", bevel: 0.0006, seg: 10)
        // Domed lid on a hinge at the back, with steam cap and latch button at the front.
        K.lathe(&m, [(0.0, 0.158), (0.05, 0.1585), (0.09, 0.1565), (0.112, 0.152), (0.1165, 0.1545), (0.1165, 0.162), (0.112, 0.17), (0.09, 0.19), (0.05, 0.204), (0.02, 0.208), (0.0, 0.209)], at: .zero, body, seg: 48)
        m.add(Prim.torus(major: 0.1165, minor: 0.0013, segments: 48, sides: 6, material: K.dark), Xform(translation: V3(0, 0.1575, 0)))
        K.cyl(&m, r: 0.022, h: 0.012, at: V3(0, 0.206, 0), gray, bevel: 0.003, seg: 20)
        K.cyl(&m, r: 0.012, h: 0.006, at: V3(0, 0.216, 0), "plastic.black", bevel: 0.002, seg: 14)
        for i in 0..<6 { K.seam(&m, V3(0.002, 0.0016, 0.008), V3(Float(i - 3) * 0.006 + 0.003, 0.2165, 0)) }
        // Hinge barrel and bracket (back), latch button (front).
        K.cylX(&m, r: 0.009, len: 0.07, at: V3(-0.035, 0.158, -0.122), gray, seg: 14)
        K.box(&m, V3(0.07, 0.028, 0.014), V3(0, 0.145, -0.1235), gray, r: 0.003)
        K.box(&m, V3(0.05, 0.02, 0.016), V3(0, 0.168, 0.1175), gray, r: 0.004)
        K.box(&m, V3(0.034, 0.012, 0.01), V3(0, 0.156, 0.1215), "plastic.black", r: 0.003)
        // Side handles: black loops riveted to the body.
        for sx: Float in [-1, 1] {
            let x0 = sx * 0.118
            let p = catmull([V3(x0, 0.13, -0.025), V3(x0 + sx * 0.008, 0.133, -0.022), V3(x0 + sx * 0.014, 0.12, 0), V3(x0 + sx * 0.008, 0.107, 0.022), V3(x0, 0.11, 0.025)], per: 8)
            m.add(Prim.tube(p, radii: p.map { _ in 0.007 }, sides: 12, seamTile: 0.05, material: "plastic.cordless-worn", capEnd: true), Xform())
        }
        // Front control block: black fascia, cook lever, lamps.
        K.box(&m, V3(0.13, 0.062, 0.03), V3(0, 0.068, 0.115), "plastic.matte:2A2A2C", r: 0.008)
        K.box(&m, V3(0.05, 0.02, 0.012), V3(-0.025, 0.07, 0.136), body, r: 0.005)
        K.box(&m, V3(0.05, 0.004, 0.008), V3(-0.025, 0.083, 0.133), "plastic.matte:3A3A3D", r: 0.001)
        K.cylZ(&m, r: 0.0055, len: 0.003, at: V3(0.03, 0.082, 0.1295), "emissive.signal-orange", bevel: 0.0008, seg: 10)
        K.cylZ(&m, r: 0.0055, len: 0.003, at: V3(0.048, 0.082, 0.1295), "emissive.signal-green", bevel: 0.0008, seg: 10)
        K.box(&m, V3(0.02, 0.003, 0.002), V3(0.04, 0.058, 0.1305), "plastic.white", r: 0.0004)
        // Rice scoop: clipped upright on the right side (story detail), scuffed handle.
        K.cyl(&m, r: 0.02, h: 0.003, at: V3(0.095, 0.045, -0.035), "plastic.matte:E8E4D8", bevel: 0.001, seg: 18)
        K.box(&m, V3(0.014, 0.1, 0.007), V3(0.1, 0.12, -0.0), "plastic.matte:E8E4D8", r: 0.003)
        K.cord(&m, from: V3(0.05, 0.03, -0.1), to: V3(0.1, 0, -0.14))
        // Story: spilled rice grains on the counter and starch dribble on the body.
        for i in 0..<12 {
            K.blob(&m, V3(0.1 + Float(i % 4) * 0.012, 0.0015 + foot, 0.06 + Float(i / 4) * 0.014), V3(0.007, 0.003, 0.003), "food.rice", yaw: Float(i) * 31)
        }
        K.drip(&m, at: V3(0.06, 0.15, 0.1), w: 0.006, len: 0.05, "food.rice")
        groundAO(&m)
        return LODModel(m)
    }
}
