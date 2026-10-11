import simd
import Foundation

/// Linear trench drain, 2.0 x 0.3 m: a polymer-concrete channel flush with the paving, topped with a
/// galvanized slotted grate (22 mm bars on 32 mm pitch, two lengthwise rails), dark sump below.
public struct TrenchDrain: RealAsset {
    public static let id = "trench-drain"
    public static let summary = "Trench drain, 2 x 0.3 m: concrete channel with galvanized slotted grate and dark sump."
    public static let tags = ["prop", "street", "city", "urban", "outdoor", "ground", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 45, distance: 2.2, studio: true)

    /// Channel length and width (m).
    public var length: Float = 2.0
    public var width: Float = 0.3
    /// Bar pitch (m).
    public var pitch: Float = 0.032
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.05, bar: Float = 0.02
        GK.box(&m, V3(0, top / 2, 0), V3(length + 0.2, top, width + 0.2), "concrete.sidewalk", r: 0.005)
        GK.box(&m, V3(0, top + 0.0005, 0), V3(length - 0.02, 0.002, width - 0.04), "asphalt.sealant", r: 0.0005)
        // Edge rails.
        for s: Float in [-1, 1] {
            GK.box(&m, V3(0, top - 0.006, s * (width / 2 - 0.006)), V3(length, 0.012, 0.012), "metal.galvanized", r: 0.002)
        }
        // Bars across the channel.
        let n = Int((length - 0.02) / pitch)
        for i in 0..<n {
            let x = -length / 2 + 0.02 + Float(i) * pitch + bar / 2
            GK.box(&m, V3(x, top - 0.012, 0), V3(bar, 0.026, width - 0.014), i % 7 == 3 ? "metal.galvanized-aged" : "metal.galvanized", r: 0.003)
        }
        // Silt and a few leaves on the grate.
        for _ in 0..<5 {
            m.add(Prim.superellipsoid(V3(rng.float(0.03...0.06), 0.002, rng.float(0.02...0.04)), exponent: 2, subdivisions: 2, material: "leaf.oak"),
                  Xform(translation: V3(rng.float(-0.9...0.9), top + 0.003, rng.float(-0.08...0.08)), rotation: simd_quatf(angle: rng.float(0...6.28), axis: .up)))
        }
        return GK.finish(&m, ao: 0.07)
    }
}
