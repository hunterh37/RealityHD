import simd
import Foundation

/// Bike lane marking, 1.8 x 3.0 m: green-painted lane section with a white bicycle pictogram
/// (two 36 cm wheels, frame, bars) and a chevron, over asphalt.
public struct BikeLaneSymbol: RealAsset {
    public static let id = "bike-lane-symbol"
    public static let summary = "Bike lane marking, 1.8 x 3 m: green painted lane with a white bicycle pictogram and chevron."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground"]
    public static let budget = 4500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 55, distance: 3.6, studio: true)

    /// Lane paint (sRGB hex).
    public var green: UInt32 = 0x2F7D4F
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.04, wmat = GK.paintWhite
        GK.slab(&m, w: 1.8, d: 3.0, h: top, "asphalt.road", r: 0.01)
        GK.layer(&m, x: 0, z: 0, w: 1.6, d: 2.9, top: top, "paint.lane-white:" + String(format: "%06X", green))
        // Pictogram: wheels along Z.
        for z: Float in [-0.45, 0.45] {
            m.add(Prim.torus(major: 0.36, minor: 0.022, segments: 28, sides: 6, minorY: 0.0016, material: wmat), Xform(translation: V3(0, top + 0.0025, z)))
            GK.layer(&m, x: 0, z: z, w: 0.05, d: 0.05, top: top + 0.0005, wmat)
        }
        func bar(_ a: V2, _ b: V2, _ w: Float) {
            let d = simd_normalize(b - a), n = V2(-d.y, d.x) * w / 2
            GK.poly(&m, [a - n, b - n, b + n, a + n], top: top + 0.0005, wmat)
        }
        let rear = V2(0, -0.45), front = V2(0, 0.45), seat = V2(0, -0.2), bars = V2(0, 0.35)
        bar(rear, seat, 0.03); bar(seat, bars, 0.03); bar(rear, V2(0, 0.05), 0.03); bar(V2(0, 0.05), front, 0.03)
        bar(V2(-0.16, 0.38), V2(0.16, 0.38), 0.03); bar(V2(-0.07, -0.22), V2(0.07, -0.22), 0.035)
        // Chevron.
        GK.poly(&m, [V2(-0.5, 1.0), V2(0, 1.28), V2(0.5, 1.0), V2(0.5, 1.12), V2(0, 1.4), V2(-0.5, 1.12)], top: top + 0.0005, wmat)
        GK.layer(&m, x: rng.float(-0.5...0.5), z: rng.float(-1...1), w: 0.3, d: 0.6, top: top + 0.002, "asphalt.worn")
        return GK.finish(&m, ao: 0.03)
    }
}
