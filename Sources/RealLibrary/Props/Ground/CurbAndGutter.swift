import simd
import Foundation

/// Poured concrete curb and gutter, 2.0 m run: 45 cm gutter pan sloping to a 15 cm curb face with a
/// rounded top, a contraction joint every metre and an asphalt road edge alongside.
public struct CurbAndGutter: RealAsset {
    public static let id = "curb-and-gutter"
    public static let summary = "Concrete curb and gutter, 2 m: sloped gutter pan, 17 cm curb with rounded top, joints, asphalt edge."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground", "concrete"]
    public static let budget = 3500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 45, elevation: 30, distance: 2.4, studio: true)

    /// Run length along the street (m).
    public var length: Float = 2.0
    /// Curb reveal height (m).
    public var reveal: Float = 0.17
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Profile in (across, up): street at -x, backfill at +x.
        let outline = Shape2D.rounded([V2(-0.5, 0), V2(0.28, 0), V2(0.28, reveal), V2(0.12, reveal), V2(0.11, 0.04), V2(-0.5, 0.05)], radius: 0.01)
        m.add(Prim.extrude(outline, depth: length, bevel: 0.003, bevelSegments: 1, material: "concrete.sidewalk"))
        // Asphalt road edge, 5 mm above the gutter lip.
        GK.box(&m, V3(-0.5 - 0.35, 0.03, 0), V3(0.7, 0.06, length), "asphalt.road", r: 0.004)
        // Contraction joints and a mid-run hairline.
        for z: Float in [-length / 4, length / 4] {
            GK.box(&m, V3(-0.19, 0.049, z), V3(0.62, 0.004, 0.008), "asphalt.sealant", r: 0.0005)
            GK.box(&m, V3(0.2, reveal + 0.0015, z), V3(0.14, 0.003, 0.008), "asphalt.sealant", r: 0.0005)
        }
        // Grit and leaves collected in the pan.
        GK.layer(&m, x: -0.1, z: 0, w: 0.16, d: length - 0.1, top: 0.043, "ground.mud")
        for _ in 0..<6 {
            m.add(Prim.superellipsoid(V3(rng.float(0.04...0.07), 0.002, rng.float(0.03...0.05)), exponent: 2, subdivisions: 2, material: "leaf.oak"),
                  Xform(translation: V3(rng.float(-0.35...0.05), 0.05, rng.float(-0.9...0.9)), rotation: simd_quatf(angle: rng.float(0...6.28), axis: .up)))
        }
        return GK.finish(&m, ao: 0.08)
    }
}
