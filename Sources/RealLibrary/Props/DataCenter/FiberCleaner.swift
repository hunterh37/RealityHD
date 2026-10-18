import simd
import Foundation

/// Fiber cleaner: push-type one-click LC/SC cleaning pen, blue ridged grip, tapered nose, gray tip cap and a pocket clip. Parts: blue ridged body, tapered nose, gray tip cap, pocket clip, printed label band, end button.
public struct FiberCleaner: RealAsset {
    public static let id = "fiber-cleaner"
    public static let summary = "Push-type one-click LC/SC fiber cleaning pen, blue ridged body, gray tip cap and pocket clip, standing upright."
    public static let tags = ["prop", "handheld"]
    public static let budget = 1200
    public static let author = "realityhd"

    /// Overall size in meters (x width incl. clip, y length, z width).
    public var size = V3(0.028, 0.18, 0.024)
    /// Body radius in meters.
    public var bodyRadius: Float = 0.0115
    /// Body material.
    public var body: MaterialKey = "plastic.matte:2A6BD6"
    /// Tip cap material.
    public var cap: MaterialKey = "plastic.matte:8B8E92"
    /// Clip and button metal.
    public var metal: MaterialKey = "metal.steel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = bodyRadius
        let H = size.y
        // Grip body: end button, ridged grip (five rounded ridges), shoulder up to the nose.
        var prof: [V2] = [V2(0, 0), V2(R * 0.8, 0), V2(R * 0.9, 0.003), V2(R, 0.006)]
        let ridgeY0: Float = 0.016
        for k in 0..<5 {
            let y = ridgeY0 + Float(k) * 0.0145
            prof += [V2(R * 0.93, y), V2(R * 1.0, y + 0.0035), V2(R * 1.0, y + 0.0075), V2(R * 0.93, y + 0.011)]
        }
        let gripTop: Float = 0.105
        prof += [V2(R, gripTop - 0.004), V2(R * 0.96, gripTop), V2(R * 0.72, gripTop + 0.012), V2(R * 0.62, gripTop + 0.03), V2(R * 0.62, H - 0.017), V2(0, H - 0.017)]
        m.add(Prim.lathe(prof, segments: 12, seamTile: 0.05, material: body))
        // Gray tip cap: open-ended sleeve with a lip and a dark recess.
        let rc = R * 0.58
        m.add(Prim.lathe([V2(rc * 0.55, H), V2(rc * 0.8, H), V2(rc, H - 0.002), V2(rc, H - 0.017), V2(rc * 1.1, H - 0.019), V2(rc * 1.1, H - 0.021), V2(0, H - 0.021)],
                         segments: 14, seamTile: 0.05, material: cap))
        m.add(Prim.lathe([V2(0, H - 0.012), V2(rc * 0.55, H - 0.012), V2(rc * 0.55, H - 0.0005), V2(0, H - 0.0005)], segments: 10, seamTile: 0.05, material: "plastic.matte:0C0D0F"))
        // Pocket clip: steel strip on +x with a bent top and a pivot boss.
        m.add(cuboid(V3(0.0012, 0.082, 0.005), material: metal), Xform(translation: V3(R + 0.0035, 0.099, 0)))
        m.add(cuboid(V3(0.0045, 0.006, 0.005), material: metal), Xform(translation: V3(R + 0.0017, 0.061, 0)))
        m.add(cuboid(V3(0.0038, 0.0035, 0.005), material: metal), Xform(translation: V3(R + 0.0006, 0.1385, 0)))
        // Printed label band (white) and a dark LC/SC marking bar on the -z side.
        m.add(Prim.lathe([V2(R * 1.0 + 0.0003, 0.0905), V2(R * 1.0 + 0.0003, 0.0985)], segments: 12, seamTile: 0.05, material: "plastic.matte:EDEEF0"))
        for k in 0..<3 {
            m.add(cuboid(V3(0.0035 + Float(k) * 0.0012, 0.0013, 0.0004), material: "plastic.matte:0B1B3A"),
                  Xform(translation: V3(-0.0024 + Float(k) * 0.0006, 0.0925 + Float(k) * 0.0025, -(R + 0.0009))))
        }
        // Wear: grey scuffs on two ridges.
        for _ in 0..<3 {
            let y = ridgeY0 + Float(rng.next() % 5) * 0.0145 + 0.0055
            let a = Float(rng.next() % 360) * .pi / 180
            m.add(cuboid(V3(0.0035, 0.0018, 0.0006), material: "plastic.matte:7FA3E0"),
                  Xform(translation: V3(sin(a) * (R + 0.0002), y, cos(a) * (R + 0.0002)), rotation: simd_quatf(angle: a, axis: V3(0, 1, 0))))
        }
        // Fingerprint-worn patch on the grip: slightly lighter band.
        m.add(Prim.lathe([V2(R * 0.995, 0.058), V2(R * 1.0 + 0.0001, 0.064)], segments: 12, seamTile: 0.05, material: "plastic.matte:3F7BE0"))
        groundAO(&m)
        return LODModel(m)
    }
}
