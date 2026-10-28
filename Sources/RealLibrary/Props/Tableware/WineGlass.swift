import simd
import Foundation

/// Wine glass: everyday tableware, stemmed crystal. Parts: tulip bowl with thin rim, drawn stem, disc foot with folded edge, dried wine residue ring inside the bowl.
public struct WineGlass: RealAsset {
    public static let id = "wine-glass"
    public static let summary = "Stemmed crystal wine glass: tulip bowl, thin lip, drawn stem, disc foot, one dried wine ring."
    public static let tags = ["prop", "interior", "glass", "container", "handheld"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.08, 0.21, 0.08)
    /// Glass material.
    public var glass: MaterialKey = "glass.clear"
    /// Dried residue material.
    public var residue: MaterialKey = "plastic.matte:4A1620"
    public init() {}

    static let outer: [V2] = [
        V2(0, 0.0042), V2(0.02, 0.0030), V2(0.036, 0.0010), V2(0.0396, 0.0004), V2(0.0402, 0.0016), V2(0.0392, 0.0030),
        V2(0.030, 0.0036), V2(0.020, 0.0048), V2(0.011, 0.0078), V2(0.0058, 0.0140), V2(0.0040, 0.025), V2(0.0034, 0.050),
        V2(0.0034, 0.085), V2(0.0043, 0.098), V2(0.0075, 0.106), V2(0.0165, 0.114), V2(0.0262, 0.128), V2(0.0322, 0.145),
        V2(0.0347, 0.160), V2(0.0342, 0.176), V2(0.0316, 0.195), V2(0.0290, 0.2088), V2(0.0287, 0.2100)]

    func make(_ seg: Int, _ detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let wall: Float = 0.0012, floorY: Float = 0.1085
        let (outerWall, innerWall) = DD1FTableware.shellSplit(outer: Self.outer, wall: wall, floorY: floorY, smooth: detail ? 7 : 2)
        m.add(Prim.lathe(outerWall, segments: seg, seamTile: 0.12, material: glass))
        m.add(Prim.lathe(innerWall, segments: seg, seamTile: 0.12, material: glass))
        // Dried wine ring: a thin band on the inner wall at the old fill line, slightly uneven in height.
        let y1: Float = 0.1415, y0: Float = 0.1375
        func ri(_ y: Float) -> Float { DD1FTableware.radius(Self.outer, at: y) - wall - 0.0002 }
        m.add(DD1FTableware.band([V2(ri(y1) - 0.0006, y1), V2(ri(y1) - 0.0010, y1 - 0.0015), V2(ri(y0) - 0.0006, y0)], segments: seg, material: residue))
        if detail {
            // A few runs of residue dribbling down below the ring.
            for (i, a) in [0.6, 2.4, 4.1].enumerated() {
                let len: Float = 0.006 + Float(i) * 0.003
                let yy = y0 - len / 2
                let n = V3(cos(Float(a)), 0, sin(Float(a)))
                m.add(Prim.superellipsoid(V3(0.0016, len, 0.0007), exponent: 2, subdivisions: 2, material: residue),
                      Xform(translation: V3(n.x * (ri(yy) - 0.0005), yy, n.z * (ri(yy) - 0.0005)), rotation: simd_quatf(angle: -Float(a) - .pi / 2, axis: V3(0, 1, 0))))
            }
        }
        groundAO(&m, height: 0.02, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [make(32, true), make(28, false)], switchDistances: [3])
    }
}
