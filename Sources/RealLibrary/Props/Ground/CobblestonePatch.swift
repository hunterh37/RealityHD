import simd
import Foundation

/// Granite cobblestone patch, 1.0 x 1.0 m: 10 x 10 cm setts in running bond over a sand bed, each sett
/// rounded, varied in tone, height and tilt, with sand-filled joints.
public struct CobblestonePatch: RealAsset {
    public static let id = "cobblestone-patch"
    public static let summary = "Granite cobblestone patch, 1 x 1 m: rounded 10 cm setts in running bond with sand joints."
    public static let tags = ["prop", "street", "urban", "outdoor", "ground", "stone"]
    public static let budget = 11_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 1.3, studio: true)

    /// Patch size (m).
    public var size: Float = 1.0
    /// Sett size X, Z (m).
    public var sett = V2(0.1, 0.1)
    /// Sett height (m).
    public var height: Float = 0.08
    /// Tones (sRGB hex) mixed across the field.
    public var tones: [UInt32] = [0x8A8A8C, 0x77777A, 0x9A9690, 0x6E6D70]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let joint: Float = 0.012
        GK.slab(&m, w: size, d: size, h: height * 0.5, "ground.sand", r: 0.004)
        let cols = Int(size / (sett.x + joint)), rows = Int(size / (sett.y + joint))
        for j in 0..<rows {
            let off = j % 2 == 0 ? Float(0) : (sett.x + joint) / 2
            for i in 0..<cols {
                let x = -size / 2 + (Float(i) + 0.5) * (sett.x + joint) + off - (sett.x + joint) * 0.25
                guard abs(x) < size / 2 - 0.03 else { continue }
                let z = -size / 2 + (Float(j) + 0.5) * (sett.y + joint)
                let h = height * rng.float(0.92...1.04), tone = rng.pick(tones)
                m.add(Prim.roundedBox(V3(sett.x * rng.float(0.92...1.0), h, sett.y * rng.float(0.92...1.0)), radius: 0.018, bevelSegments: 1,
                                      material: "stone.granite-paver:" + String(format: "%06X", tone)),
                      Xform(translation: V3(x, h / 2, z), rotation: simd_quatf(degrees: rng.float(-4...4), axis: .up)))
            }
        }
        return GK.finish(&m, ao: 0.06)
    }
}
