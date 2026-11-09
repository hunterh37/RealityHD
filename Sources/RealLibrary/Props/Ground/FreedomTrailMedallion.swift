import simd
import Foundation

/// Freedom Trail ground medallion, 0.20 m diameter cast bronze disc set flush in brick: flat ground plate with a
/// raised rolled rim, a beaded ring, a recessed field and a raised eight-point compass star with a center
/// boss. 20 mm tall at the rim. Up +Y, base at y = 0. Anchors: `medallion.center`, `medallion.rim`.
public struct FreedomTrailMedallion: RealAsset {
    public static let id = "freedom-trail-medallion"
    public static let summary = "Freedom Trail ground medallion: 0.2 m cast bronze disc with raised rim, bead ring, recessed field and eight-point star boss."
    public static let tags = ["prop", "ground", "metal", "outdoor", "urban"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 0.45, studio: true)

    /// Plate bronze.
    public var bronze: MaterialKey = "metal.bronze-cast"
    /// Weathered relief.
    public var relief: MaterialKey = "metal.bronze-weathered"
    public init() {}

    public var anchors: [String: Xform] {
        ["medallion.center": Xform(translation: V3(0, 0.0135, 0)), "medallion.rim": Xform(translation: V3(0.1, 0.02, 0))]
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let prof: [V2] = [V2(0, 0), V2(0.099, 0), V2(0.1, 0.003), V2(0.1, 0.014), V2(0.0985, 0.0185), V2(0.096, 0.02), V2(0.0925, 0.0185),
                          V2(0.0905, 0.0135), V2(0.088, 0.0115), V2(0.0855, 0.0105), V2(0.0, 0.0105)]
        m.add(Prim.lathe(prof, segments: 128, seamTile: 0.1, material: bronze))
        m.add(Prim.torus(major: 0.0775, minor: 0.0016, segments: 128, sides: 16, material: relief), Xform(translation: V3(0, 0.0112, 0)))
        m.add(Prim.torus(major: 0.0615, minor: 0.0012, segments: 128, sides: 16, material: relief), Xform(translation: V3(0, 0.0112, 0)))
        var star: [V2] = []
        for i in 0..<16 { let a = Float(i) / 16 * 2 * .pi, r: Float = i % 2 == 0 ? 0.058 : 0.0215; star.append(V2(r * sin(a), r * cos(a))) }
        m.add(Prim.extrude(star, depth: 0.003, bevel: 0.0008, bevelSegments: 2, material: relief), Xform(translation: V3(0, 0.0120, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.lathe([V2(0, 0.0125), V2(0.013, 0.0125), V2(0.0145, 0.0138), V2(0.012, 0.0165), V2(0.006, 0.0182), V2(0, 0.0186)], segments: 64, seamTile: 0.05, material: relief))
        groundAO(&m, height: 0.02, floor: 0.7)
        return LODModel(m)
    }
}
