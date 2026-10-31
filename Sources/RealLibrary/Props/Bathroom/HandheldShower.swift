import simd
import Foundation

/// Handheld shower: everyday bathroom, chrome. Parts: head with nozzle rings, grip handle, hose nipple, wall bracket.
public struct HandheldShower: RealAsset {
    public static let id = "handheld-shower"
    public static let summary = "Chrome handheld shower in a wall clamp: round head with nozzle rings, ringed handle, hose nipple."
    public static let tags = ["prop", "interior", "bathroom", "metal"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.06, 0.28, 0.06)
    public init() {}

    public var chrome: MaterialKey = "metal.chrome"
    public var rubber: MaterialKey = "plastic.matte:2B2F34"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let seg = 28
        // Handle, bottom hose nipple to neck.
        Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.0065, 0.0), V2(0.0065, 0.006), V2(0.0095, 0.008), V2(0.0115, 0.03), V2(0.0125, 0.1), V2(0.0125, 0.16), V2(0.0105, 0.21), V2(0.0085, 0.235), V2(0.0085, 0.246)], chrome, seg: seg)
        for y: Float in [0.05, 0.07, 0.09] { Toiletry.band(&m, r: 0.0121, y, y + 0.004, rubber, seg: seg) }
        // Smudged patch on the handle where it is held.
        Toiletry.band(&m, r: 0.0126, 0.135, 0.15, "metal.stainless-smudged", seg: seg)
        // Head, tilted so its face points forward and slightly up.
        let tilt = simd_quatf(angle: 70 * Float.pi / 180, axis: V3(1, 0, 0))
        let hat = V3(0, 0.244, 0)
        Toiletry.lathe(&m, [V2(0.0085, 0.0), V2(0.0095, 0.006), V2(0.02, 0.012), V2(0.03, 0.017), V2(0.0305, 0.022), V2(0.028, 0.0245), V2(0.001, 0.0245)], chrome, seg: 36, at: hat, rot: tilt)
        Toiletry.lathe(&m, [V2(0.001, 0.0243), V2(0.0262, 0.0243), V2(0.0262, 0.0248), V2(0.001, 0.0248)], "plastic.black", seg: 36, at: hat, rot: tilt)
        for r: Float in [0.005, 0.0105, 0.016, 0.0215] {
            Toiletry.lathe(&m, [V2(r, 0.0247), V2(r + 0.0016, 0.0247), V2(r + 0.0016, 0.0253), V2(r, 0.0253)], "plastic.matte:6D737A", seg: 36, at: hat, rot: tilt)
        }
        // Wall clamp ring, arm and plate.
        Toiletry.lathe(&m, [V2(0.0124, 0.108), V2(0.0165, 0.109), V2(0.0165, 0.131), V2(0.0124, 0.132)], chrome, seg: seg)
        m.add(Prim.roundedBox(V3(0.032, 0.07, 0.008), radius: 0.003, bevelSegments: 2, material: chrome), Xform(translation: V3(0, 0.12, -0.0205)))
        groundAO(&m)
        return LODModel(m)
    }
}
