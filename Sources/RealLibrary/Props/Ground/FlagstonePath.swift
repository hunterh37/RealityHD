import simd
import Foundation

/// Flagstone path, 1.2 x 1.8 m: irregular 3-5 cm sandstone flags with rounded corners, spaced 2 cm
/// apart on a packed-earth bed, each flag varied in tone, thickness and tilt, with moss in the joints.
public struct FlagstonePath: RealAsset {
    public static let id = "flagstone-path"
    public static let summary = "Flagstone path, 1.2 x 1.8 m: irregular sandstone flags on packed earth with moss in the joints."
    public static let tags = ["prop", "ground", "garden", "outdoor", "stone"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 50, distance: 2.2, studio: true)

    /// Path size X, Z (m).
    public var size = V2(1.2, 1.8)
    /// Flag tones (sRGB hex).
    public var tones: [UInt32] = [0xA89A82, 0x9C8F78, 0xB5A68B, 0x8E8570]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        GK.slab(&m, w: size.x, d: size.y, h: 0.02, "ground.dirt", r: 0.004)
        var z = -size.y / 2 + 0.03
        while z < size.y / 2 - 0.2 {
            let rowH = rng.float(0.32...0.46)
            var x = -size.x / 2 + 0.03
            while x < size.x / 2 - 0.15 {
                let w = min(rng.float(0.28...0.5), size.x / 2 - 0.03 - x)
                guard w > 0.15 else { break }
                let h = min(rowH, size.y / 2 - 0.03 - z)
                let cx = x + w / 2, cz = z + h / 2
                // Five to six jittered corners around an inset rectangle.
                let hw = w / 2 - 0.012, hh = h / 2 - 0.012
                let base = [V2(-hw, -hh), V2(0, -hh - rng.float(0...0.015)), V2(hw, -hh), V2(hw + rng.float(0...0.012), 0), V2(hw, hh),
                            V2(rng.float(-0.05...0.05), hh + rng.float(0...0.015)), V2(-hw, hh), V2(-hw - rng.float(0...0.012), 0)]
                let outline = Shape2D.rounded(base.map { $0 + V2(rng.float(-0.01...0.01), rng.float(-0.01...0.01)) }, radius: 0.025)
                let th = rng.float(0.032...0.05)
                m.add(Prim.extrude(outline, depth: th, bevel: 0.006, bevelSegments: 1, material: "stone.sandstone:" + String(format: "%06X", rng.pick(tones))),
                      Xform(translation: V3(cx, 0.015 + th, cz), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
                if rng.chance(0.5) {
                    m.add(Prim.superellipsoid(V3(rng.float(0.03...0.06), 0.012, 0.025), exponent: 2, subdivisions: 3, material: "ground.meadow"),
                          Xform(translation: V3(x + w + 0.01, 0.025, cz + rng.float(-0.1...0.1))))
                }
                x += w + 0.025
            }
            z += rowH + 0.025
        }
        return GK.finish(&m, ao: 0.08)
    }
}
