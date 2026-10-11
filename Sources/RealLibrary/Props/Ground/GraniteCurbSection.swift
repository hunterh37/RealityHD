import simd
import Foundation

/// Granite street curb, 1.5 m long: two 75 cm stones 15 cm wide and 46 cm deep with a 15 cm reveal,
/// asphalt gutter on the street side, concrete sidewalk behind and a hairline joint between stones.
public struct GraniteCurbSection: RealAsset {
    public static let id = "granite-curb-section"
    public static let summary = "Granite curb section, 1.5 m: two 15 x 46 cm stones with asphalt street side and concrete sidewalk."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground", "stone"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 25, distance: 1.9, studio: true)

    /// Section length along the street (m).
    public var length: Float = 1.5
    /// Curb width and height (m).
    public var width: Float = 0.15
    public var height: Float = 0.46
    /// Reveal above the street surface (m).
    public var reveal: Float = 0.15
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sidewalkW: Float = 0.6, streetW: Float = 0.6, gap: Float = 0.006
        let streetTop = height - reveal
        GK.box(&m, V3(-(width / 2 + streetW / 2), streetTop / 2, 0), V3(streetW, streetTop, length), "asphalt.road", r: 0.004)
        GK.box(&m, V3(width / 2 + sidewalkW / 2, height / 2, 0), V3(sidewalkW, height, length), "concrete.sidewalk", r: 0.004)
        let stone = (length - gap) / 2
        for s: Float in [-1, 1] {
            let tone = rng.pick([0x8E8E90, 0x7F7F82, 0x95918B])
            m.add(Prim.roundedBox(V3(width, height, stone), radius: 0.016, bevelSegments: 2, material: "stone.granite-curb:" + String(format: "%06X", tone)),
                  Xform(translation: V3(0, height / 2, s * (stone + gap) / 2)))
        }
        // Gutter pan dirt line and leaf litter at the foot.
        GK.layer(&m, x: -(width / 2 + 0.05), z: 0, w: 0.1, d: length - 0.05, top: streetTop, "ground.mud")
        for _ in 0..<5 {
            m.add(Prim.superellipsoid(V3(rng.float(0.04...0.07), 0.002, rng.float(0.03...0.05)), exponent: 2, subdivisions: 2, material: "leaf.oak"),
                  Xform(translation: V3(-(width / 2 + rng.float(0.03...0.2)), streetTop + 0.003, rng.float(-0.65...0.65)), rotation: simd_quatf(angle: rng.float(0...6.28), axis: .up)))
        }
        return GK.finish(&m, ao: 0.1)
    }
}
