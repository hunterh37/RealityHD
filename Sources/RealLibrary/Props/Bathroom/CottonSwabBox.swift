import simd
import Foundation

/// Cotton swab box: everyday bathroom, plastic. Parts: clear plastic box, hinged lid, cotton swabs, label.
public struct CottonSwabBox: RealAsset {
    public static let id = "cotton-swab-box"
    public static let summary = "Clear plastic box of cotton swabs with the hinged lid open and a front label."
    public static let tags = ["prop", "interior", "bathroom", "plastic"]
    public static let budget = 7000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.06, 0.09, 0.03)
    public init() {}

    public var wall: MaterialKey = "glass.polycarbonate"
    public var lid: MaterialKey = "plastic.gloss:F4F6F7"
    public var swab: MaterialKey = "plastic.matte:F7F4EE"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        var rng = SeededRNG(seed: seed)
        let w = size.x, d = size.z, bh: Float = 0.058, t: Float = 0.0015
        // Clear box: floor and four thin walls.
        m.add(Prim.roundedBox(V3(w, 0.003, d), radius: 0.001, bevelSegments: 1, material: wall), Xform(translation: V3(0, 0.0015, 0)))
        for sz: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(w, bh, t), radius: 0.0006, bevelSegments: 1, material: wall), Xform(translation: V3(0, bh / 2, sz * (d / 2 - t / 2))))
        }
        for sx: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(t, bh, d - 2 * t), radius: 0.0006, bevelSegments: 1, material: wall), Xform(translation: V3(sx * (w / 2 - t / 2), bh / 2, 0)))
        }
        // Swabs: 8 by 3, uneven heights and tilts, one leaning.
        let stickProfile: (Float) -> [V2] = { len in [V2(0.0012, 0.0), V2(0.0012, len), V2(0.0001, len)] }
        let tip = [V2(0.0004, 0.0), V2(0.0026, 0.0016), V2(0.0032, 0.004), V2(0.0026, 0.0075), V2(0.0008, 0.0096), V2(0.0001, 0.0099)]
        for c in 0..<8 {
            for r in 0..<3 {
                var f = rng.fork(c * 3 + r)
                let x = (Float(c) - 3.5) * 0.0068 + f.float(-0.0006...0.0006)
                let z = (Float(r) - 1) * 0.0072 + f.float(-0.0006...0.0006)
                let len = 0.07 + f.float(-0.004...0.003)
                var ax = f.float(-0.04...0.04), az = f.float(-0.04...0.04)
                if c == 6 && r == 1 { ax = 0.0; az = -0.12 }
                let q = simd_quatf(angle: ax, axis: V3(1, 0, 0)) * simd_quatf(angle: az, axis: V3(0, 0, 1))
                m.add(Prim.lathe(stickProfile(len), segments: 6, seamTile: 0.01, material: "plastic.matte:EDEBE5"), Xform(translation: V3(x, 0.004, z), rotation: q))
                m.add(Prim.lathe(tip, segments: 10, seamTile: 0.01, material: swab), Xform(translation: q.act(V3(0, len - 0.0005, 0)) + V3(x, 0.004, z), rotation: q))
            }
        }
        // Lid hinged at the back and swung open about 100 degrees, with a hinge barrel.
        m.add(Prim.roundedBox(V3(w, 0.002, d), radius: 0.0008, bevelSegments: 1, material: lid), Xform(translation: V3(0, bh + d / 2, -d / 2 + 0.001), rotation: simd_quatf(angle: -90 * Float.pi / 180, axis: V3(1, 0, 0))))
        Toiletry.rod(&m, axis: 0, at: V3(-w / 2 + 0.002, bh + 0.0005, -d / 2 + 0.0024), length: w - 0.004, r: 0.0022, lid)
        // Printed label on the front wall.
        m.add(Prim.roundedBox(V3(0.042, 0.016, 0.0004), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:F2F2EE"), Xform(translation: V3(0, 0.03, d / 2 + 0.0002)))
        m.add(Prim.roundedBox(V3(0.034, 0.003, 0.0006), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:2F6FB5"), Xform(translation: V3(0, 0.034, d / 2 + 0.0004)))
        m.add(Prim.roundedBox(V3(0.026, 0.0015, 0.0006), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:8A9097"), Xform(translation: V3(0, 0.027, d / 2 + 0.0004)))
        groundAO(&m)
        return LODModel(m)
    }
}
