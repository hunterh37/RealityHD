import simd
import Foundation

/// Stovetop pressure cooker: stainless pot with rolled rim and two riveted phenolic side handles,
/// domed lid with a locking long handle, weighted pressure regulator, safety valve and a heat-tinted base.
public struct PressureCooker: RealAsset {
    public static let id = "pressure-cooker"
    public static let summary = "Stovetop pressure cooker: stainless pot, riveted side handles, locking lid handle, pressure regulator weight."
    public static let tags = ["prop", "interior", "kitchen", "metal", "plastic"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width including side handles, y height with regulator, z depth with lid handle).
    public var size = V3(0.34, 0.30, 0.30)
    /// Pot material.
    public var steel: MaterialKey = "metal.satin-aluminum"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias K = DD1DKitchen
        let R: Float = 0.125
        let top: Float = 0.2
        _ = rng.float()
        // Pot: encapsulated heat-tinted base disc, straight wall, rolled rim.
        K.lathe(&m, [(0, 0.0), (0.1, 0.0), (0.114, 0.003), (0.114, 0.016), (0.12, 0.018), (0, 0.018)], at: .zero, "metal.heat-tint-light", seg: 48)
        K.lathe(&m, [(0.12, 0.016), (R - 0.001, 0.03), (R, 0.1), (R, top - 0.012), (R + 0.004, top - 0.006), (R + 0.002, top), (R - 0.003, top + 0.002), (R - 0.006, top - 0.004), (R - 0.0035, top - 0.012), (R - 0.004, 0.03), (0.0, 0.026)], at: .zero, steel, seg: 56)
        m.add(Prim.torus(major: R + 0.001, minor: 0.0013, segments: 56, sides: 6, material: "metal.stainless-smudged"), Xform(translation: V3(0, 0.0185, 0)))
        // Volume marks on the inside wall (stamped ridges).
        for (i, yy) in [Float(0.08), 0.125, 0.165].enumerated() {
            m.add(Prim.torus(major: R - 0.0042, minor: 0.0008, segments: 56, sides: 5, material: "metal.stainless-smudged"), Xform(translation: V3(0, yy + Float(i) * 0.0, 0)))
        }
        // Side handles: phenolic bars on stainless brackets with two rivets each.
        for sx: Float in [-1, 1] {
            let x0 = sx * (R + 0.002)
            K.box(&m, V3(0.006, 0.05, 0.04), V3(x0 + sx * 0.003, 0.15, 0), steel, r: 0.002)
            let hl: Float = 0.03
            K.cylX(&m, r: 0.0125, len: hl, at: V3(x0 + sx * 0.004 - (sx < 0 ? hl : 0), 0.15, 0), "plastic.cordless-worn", bevel: 0.004, seg: 14)
            K.cylX(&m, r: 0.015, len: 0.008, at: V3(x0 + sx * (0.004 + hl) - (sx < 0 ? 0.008 : 0), 0.15, 0), "plastic.matte:2A2A2C", bevel: 0.003, seg: 14)
            for zz: Float in [-0.012, 0.012] { rivet(&m, at: V3(x0 + sx * 0.006, 0.15, zz), normal: V3(sx, 0, 0), radius: 0.004, material: "metal.stainless") }
        }
        // Lid: low dome with a rim skirt, locking handle across the pot, regulator and safety valve.
        K.lathe(&m, [(0.0, top + 0.044), (0.03, top + 0.043), (0.08, top + 0.03), (0.118, top + 0.014), (R + 0.006, top + 0.008), (R + 0.007, top + 0.002), (R + 0.004, top - 0.004), (R - 0.006, top + 0.0)].reversed(), at: .zero, steel, seg: 56)
        m.add(Prim.torus(major: R + 0.005, minor: 0.0012, segments: 56, sides: 6, material: K.dark), Xform(translation: V3(0, top + 0.001, 0)))
        // Long locking handle along Z (phenolic over a steel strap), ends bent to the rim.
        let hz: Float = 0.15
        let hp = catmull([V3(0, top + 0.0, hz - 0.005), V3(0, top + 0.026, hz - 0.016), V3(0, top + 0.036, hz - 0.04), V3(0, top + 0.046, 0.065)], per: 6)
        m.add(Prim.tube(hp, radii: hp.map { _ in 0.0105 }, sides: 12, seamTile: 0.05, material: "plastic.cordless-worn", capEnd: true), Xform())
        K.box(&m, V3(0.02, 0.012, 0.145), V3(0, top + 0.05, -0.04), "plastic.cordless-worn", r: 0.004)
        K.box(&m, V3(0.024, 0.014, 0.02), V3(0, top + 0.03, -R - 0.012), "plastic.matte:2A2A2C", r: 0.004)
        K.box(&m, V3(0.014, 0.008, 0.026), V3(0, top + 0.004, -R - 0.01 + 0.0), steel, r: 0.002)
        // Lock slider on the handle and indicator.
        K.box(&m, V3(0.012, 0.006, 0.03), V3(0, top + 0.057, 0.02), "plastic.matte:8A8C90", r: 0.002)
        K.box(&m, V3(0.006, 0.003, 0.004), V3(0, top + 0.061, 0.03), "emissive.signal-red", r: 0.0006)
        // Regulator: weighted cap on a vent pipe at the lid centre.
        K.cyl(&m, r: 0.009, h: 0.046, at: V3(0, top + 0.044, 0.0), steel, bevel: 0.002, seg: 18)
        K.lathe(&m, [(0.0, 0.0), (0.019, 0.0), (0.0215, 0.003), (0.0215, 0.016), (0.017, 0.02), (0.012, 0.0215), (0.0, 0.0215)], at: V3(0, top + 0.0725, 0.0), "metal.stainless-smudged", seg: 28)
        K.cyl(&m, r: 0.006, h: 0.006, at: V3(0, top + 0.094, 0.0), "metal.stainless", bevel: 0.0015, seg: 12)
        // Safety valve (rubber plug) and a locking pin beside the handle.
        K.cyl(&m, r: 0.0085, h: 0.012, at: V3(0.05, top + 0.034, 0.0), "rubber.silicone-gray", bevel: 0.002, seg: 14)
        K.cyl(&m, r: 0.007, h: 0.016, at: V3(-0.055, top + 0.03, 0.0), steel, bevel: 0.002, seg: 12)
        K.cyl(&m, r: 0.01, h: 0.004, at: V3(-0.055, top + 0.045, 0.0), "metal.stainless-smudged", bevel: 0.001, seg: 12)
        // Stamped maker plate (no text) on the lid shoulder.
        K.box(&m, V3(0.036, 0.0016, 0.022), V3(0.06, top + 0.0345, 0.065), "metal.brushed-nickel", r: 0.0005)
        // Story: scorched ring around the lower wall and burnt-on streaks.
        K.lathe(&m, [(R + 0.0006, 0.03), (R + 0.0008, 0.065), (R + 0.0006, 0.07)], at: .zero, "metal.heat-tint", seg: 56)
        for i in 0..<5 {
            let a = Float(i) * 1.3
            K.blob(&m, V3(cos(a) * (R + 0.0008), 0.095 + Float(i % 2) * 0.01, sin(a) * (R + 0.0008)), V3(0.004, 0.04, 0.004), "metal.heat-tint-light", yaw: 0)
        }
        groundAO(&m)
        return LODModel(m)
    }
}
