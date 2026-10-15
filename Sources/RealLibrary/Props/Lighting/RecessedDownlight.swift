import simd
import Foundation

/// 4 in recessed LED downlight, authored in place: the trim face sits 2 mm below the ceiling plane at y = 2.6 and
/// the 4.5 cm steel housing goes up into the ceiling void. Ø150 mm white flange, ribbed baffle cone, lit LED lens,
/// galvanized can with torsion-spring clips and a junction box.
public struct RecessedDownlight: RealAsset {
    public static let id = "recessed-downlight"
    public static let summary = "4 in recessed LED downlight: white trim flange, ribbed baffle, lit LED lens, steel housing."
    public static let tags = ["prop", "floorplan", "interior", "ceiling", "light"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: -50, distance: 1.0, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.15, 0.05, 0.15)
    /// Ceiling plane height (m).
    public var ceilingY: Float = 2.6
    /// Trim color.
    public var trim: MaterialKey = "plastic.white"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let yb = ceilingY - 0.002
        let R = size.x / 2
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let seg = lod == 0 ? 40 : 20
            // Flange: closed ring section, counter-clockwise in (r, y).
            m.add(Prim.lathe([V2(0.0505, yb), V2(R - 0.0015, yb), V2(R, yb + 0.0012), V2(R, yb + 0.0028), V2(0.062, yb + 0.003), V2(0.0505, yb + 0.003)], segments: seg, seamTile: 0.2, material: trim))
            // Ribbed baffle: stepped grooves inside the aperture, visible from below.
            var baf: [V2] = [V2(0.0405, yb + 0.034)]
            for k in 0..<4 {
                let y0 = yb + 0.034 - Float(k) * 0.0075
                baf.append(V2(0.0405 + Float(k) * 0.0022, y0 - 0.0015)); baf.append(V2(0.0435 + Float(k) * 0.0022, y0 - 0.0045)); baf.append(V2(0.0435 + Float(k) * 0.0022, y0 - 0.0075))
            }
            baf.append(V2(0.0505, yb + 0.002)); baf.append(V2(0.0505, yb))
            m.add(Prim.lathe(baf, segments: seg, seamTile: 0.2, material: trim))
            // LED module: lens disc recessed at the top of the baffle, lit face.
            m.add(Prim.cylinder(radius: 0.0385, height: 0.003, bevel: 0.0005, segments: seg, bevelSegments: 1, material: "emissive.panel"), Xform(translation: V3(0, yb + 0.0315, 0)))
            m.add(Prim.lathe([V2(0.0405, yb + 0.034), V2(0.0385, yb + 0.0348), V2(0.0385, yb + 0.0345)], segments: seg, seamTile: 0.1, material: "metal.chrome"))
            // Housing above the ceiling plane.
            m.add(Prim.lathe([V2(0.062, yb + 0.003), V2(0.062, yb + 0.0445), V2(0.0605, yb + 0.046), V2(0, yb + 0.046)], segments: lod == 0 ? 32 : 16, seamTile: 0.2, material: "metal.aluminum-brushed"))
            m.add(Prim.roundedBox(V3(0.05, 0.004, 0.034), radius: 0.0012, bevelSegments: 1, material: "metal.aluminum-brushed"), Xform(translation: V3(0.02, yb + 0.046, 0.0)))
            if lod == 0 {
                for s in [-1, 1] as [Float] {
                    m.add(Prim.roundedBox(V3(0.006, 0.03, 0.0015), radius: 0.0005, bevelSegments: 1, material: "metal.chrome"), Xform(translation: V3(s * 0.0635, yb + 0.022, 0)))
                    m.add(Prim.roundedBox(V3(0.012, 0.0015, 0.008), radius: 0.0005, bevelSegments: 1, material: "metal.chrome"), Xform(translation: V3(s * 0.0635, yb + 0.0066, 0)))
                }
                rivet(&m, at: V3(0.02, yb + 0.048, 0.0), normal: .up, radius: 0.003, segments: 6, material: "metal.chrome")
            }
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [4])
    }
}
