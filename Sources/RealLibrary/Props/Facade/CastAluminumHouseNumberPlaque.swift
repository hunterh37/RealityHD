import simd
import Foundation

/// Cast aluminum house number plaque, Mid-Century Modern: 300 x 150 mm, 18 mm deep. A 6 mm cast aluminum plate with
/// rounded corners, a 14 mm raised border, a black anodized field, raised 62 mm numerals "1962" in cast aluminum, two
/// stud mounts on 8 mm standoffs with domed acorn nuts, and a hairline scratch pattern. Wear: oxidation bloom on the
/// numerals, rain dirt below them, scratches, a dinged corner.
public struct CastAluminumHouseNumberPlaque: RealAsset {
    public static let id = "cast-aluminum-house-number-plaque"
    public static let summary = "Cast aluminum house number plaque, Mid-Century Modern facade prop, 0.3 x 0.15 x 0.02 m."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 12, distance: 0.9)

    /// Numerals shown on the plate.
    public var number = "1962"
    /// Cast plate and numerals.
    public var alu: MaterialKey = "metal.aluminum-cast"
    /// Field behind the numerals.
    public var field: MaterialKey = "metal.anodized-black"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.3, H: Float = 0.15, zP: Float = 0.008, tP: Float = 0.006
        m.add(Prim.extrude(Shape2D.roundedRect(W, H, radius: 0.012, segments: 6), depth: tP, bevel: 0.0012, bevelSegments: 1, material: alu), Xform(translation: V3(0, 0, zP + tP / 2)))
        let zF = zP + tP
        m.add(Prim.extrude(Shape2D.roundedRect(0.272, 0.122, radius: 0.006, segments: 5), depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: field), Xform(translation: V3(0, 0, zF + 0.0004)))
        let zFront = zF + 0.0004 + 0.0006
        // Inner lip line where the cast border steps down to the field.
        let lip: [V3] = Shape2D.roundedRect(0.274, 0.124, radius: 0.0065, segments: 5).map { V3($0.x, $0.y, zFront - 0.0002) }
        m.add(Prim.sweep(Shape2D.circle(0.0011, segments: 6), along: lip, up: FA.Z, closedPath: true, caps: false, material: alu))
        // Raised numerals.
        let h: Float = 0.062
        let w = FS.width(number, h: h)
        FS.text(&m, number, origin: V2(-w / 2, -h / 2 + 0.002), h: h, w: 0.0085, z: zFront + 0.00175, t: 0.0035, alu)
        // Studs, standoffs and acorn nuts through the border.
        let acorn: [(Float, Float)] = [(0, 0), (0.0066, 0), (0.0066, 0.0014), (0.0058, 0.0034), (0.0036, 0.005), (0, 0.0056)]
        for sgn: Float in [-1, 1] {
            let x = sgn * 0.143
            FA.cylZ(&m, r: 0.0048, h: zP, at: V3(x, 0, 0), "metal.steel", bevel: 0.0008, segments: 10)
            m.add(turned(acorn, segments: 14, material: "metal.satin-aluminum", seamTile: 0.1, grainVertical: true), Xform(translation: V3(x, 0, zF), rotation: FA.q(90, FA.X)))
        }
        // Weathering: oxide bloom on the numerals, rain dirt below, scratches, corner ding.
        for _ in 0..<12 {
            FS.blob(&m, at: V3(rng.float(-0.09...0.09), rng.float(-0.025...0.03), zFront + 0.0036), size: V3(rng.float(0.003...0.007), rng.float(0.002...0.005), 0.0008), "stone.limestone")
        }
        for _ in 0..<6 {
            FS.blob(&m, at: V3(rng.float(-0.1...0.1), rng.float(-0.05...(-0.034)), zFront + 0.0003), size: V3(rng.float(0.003...0.006), rng.float(0.016...0.034), 0.0006), "stone.limestone-sooted")
        }
        for _ in 0..<9 {
            let a = V2(rng.float(-0.12...0.12), rng.float(-0.05...0.05))
            FS.bar(&m, a, a + V2(rng.float(0.01...0.03), rng.float(-0.01...0.01)), w: 0.0007, z: zFront + 0.0002, t: 0.0004, "metal.steel")
        }
        FS.blob(&m, at: V3(0.146, 0.069, zF + 0.0004), size: V3(0.012, 0.009, 0.0016), "metal.steel")
        FS.blob(&m, at: V3(-0.07, 0.07, zF + 0.0004), size: V3(0.03, 0.003, 0.0014), "stone.limestone")
        groundAO(&m)
        return LODModel(FC.place(m))
    }
}
