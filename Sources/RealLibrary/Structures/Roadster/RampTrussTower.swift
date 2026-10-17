import simd
import Foundation

/// White steel box truss tower, 27 m tall on a 1.2 m square plan, with a 3.6 m overhead arm at the top
/// reaching toward -X (over the ramp). Origin at the base center.
public struct RampTrussTower: RealAsset {
    public static let id = "ramp-truss-tower"
    public static let summary = "White steel box truss tower 27 m tall with a 3.6 m overhead arm at the top, diagonal-braced bays."
    public static let tags = ["structure", "metal"]
    public static let budget = 30000
    public static let author = "realityhd"

    /// Tower height in meters.
    public var height: Float = 27
    /// Square plan width in meters (chord centers).
    public var plan: Float = 1.2
    /// Bay height in meters.
    public var bay: Float = 0.9
    /// Overhead arm length toward -X in meters.
    public var arm: Float = 3.6
    /// Steel paint key.
    public var steel: MaterialKey = "metal.painted:E6E8E8"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let h = plan / 2, c: Float = 0.12, d: Float = 0.07
        let bays = Int((height / bay).rounded())
        m.add(Prim.roundedBox(V3(plan + 0.5, 0.12, plan + 0.5), radius: 0.01, bevelSegments: 1, material: "concrete.smooth:7A7D7B"), Xform(translation: V3(0, 0.06, 0)))
        let corners: [V2] = [V2(-h, -h), V2(h, -h), V2(h, h), V2(-h, h)]
        func bar(_ a: V3, _ b: V3, _ t: Float) {
            let v = b - a, len = simd_length(v)
            m.add(cuboid(V3(t, len, t), material: steel), Xform(translation: (a + b) / 2, rotation: simd_quatf(from: V3(0, 1, 0), to: v / len)))
        }
        for p in corners { m.add(cuboid(V3(c, height - 0.12, c), material: steel), Xform(translation: V3(p.x, 0.12 + (height - 0.12) / 2, p.y))) }
        for i in 0...bays {
            let y = 0.12 + (height - 0.12) * Float(i) / Float(bays)
            for k in 0..<4 {
                let a = corners[k], b = corners[(k + 1) % 4]
                if i > 0 { bar(V3(a.x, y, a.y), V3(b.x, y, b.y), d * 1.2) }
            }
        }
        for i in 0..<bays {
            let y0 = 0.12 + (height - 0.12) * Float(i) / Float(bays), y1 = 0.12 + (height - 0.12) * Float(i + 1) / Float(bays)
            for k in 0..<4 {
                let a = corners[k], b = corners[(k + 1) % 4]
                let flip = (i + k) % 2 == 0
                bar(V3(a.x, flip ? y0 : y1, a.y), V3(b.x, flip ? y1 : y0, b.y), d)
            }
        }
        // Overhead arm: two top chords and two lower chords with diagonals, toward +X.
        let top = height, ah: Float = 0.8
        for z: Float in [-h * 0.6, h * 0.6] {
            for y in [top, top - ah] { m.add(cuboid(V3(arm, 0.07, 0.07), material: steel), Xform(translation: V3(arm / 2 + h, y, z))) }
        }
        let segs = Int(arm / 0.9)
        for i in 0..<segs {
            let x0 = h + arm * Float(i) / Float(segs), x1 = h + arm * Float(i + 1) / Float(segs)
            for z: Float in [-h * 0.6, h * 0.6] {
                bar(V3(x0, i % 2 == 0 ? top - ah : top, z), V3(x1, i % 2 == 0 ? top : top - ah, z), d)
            }
            bar(V3(x1, top - ah, -h * 0.6), V3(x1, top - ah, h * 0.6), d)
            bar(V3(x1, top, -h * 0.6), V3(x1, top, h * 0.6), d)
        }
        return LODModel(m)
    }
}
