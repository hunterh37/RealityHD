import simd
import Foundation

/// Napkin ring, 5 cm across and 4 cm wide, standing on its rim: a thin brushed-nickel band with a rolled bead at each end, two raised
/// decorative bands, a brazed seam strip down the outside and a dent near the top. Bead and bands show polished wear.
public struct ClothNapkinRing: RealAsset {
    public static let id = "cloth-napkin-ring"
    public static let summary = "Napkin ring, brushed metal: band with rolled rims, brazed seam, raised bands, worn polished high points, one dent."
    public static let tags = ["prop", "interior", "tableware", "metal"]
    public static let budget = 8500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.1, studio: true)

    /// Overall size in meters (x diameter, y diameter, z width).
    public var size = V3(0.05, 0.05, 0.04)
    /// Band wall thickness in meters.
    public var wall: Float = 0.0014
    /// Band metal.
    public var band: MaterialKey = "metal.brushed-nickel"
    /// Worn polished beads and raised bands.
    public var polished: MaterialKey = "metal.nickel-worn"
    /// Brazed seam.
    public var braze: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [3])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var ring = Model(name: "ring")
        let R = size.x / 2, H = size.z, ri = R - wall, seg = detail ? 56 : 32
        // Closed shell profile: inner bottom, out along the bottom face, up the outside, back along the top face, down the inside.
        var prof: [V2] = [V2(ri, 0.0006), V2(R - 0.0004, 0.0006)]
        let steps = detail ? 16 : 6
        for k in 0...steps { prof.append(V2(R, 0.0012 + (H - 0.0024) * Float(k) / Float(steps))) }
        prof.append(V2(R - 0.0004, H - 0.0006)); prof.append(V2(ri, H - 0.0006))
        for k in stride(from: steps, through: 0, by: -1) { prof.append(V2(ri, 0.0012 + (H - 0.0024) * Float(k) / Float(steps))) }
        prof.append(prof[0])
        var body = Prim.lathe(prof, segments: seg, seamTile: 0.05, material: band)
        let a: Float = -50 * .pi / 180
        let dent = V3(cos(a) * R, 0.0275, sin(a) * R)
        body.displace { p, n in -0.0011 * exp(-simd_length_squared(p - dent) / (2 * 0.0065 * 0.0065)) * (n.y * n.y < 0.5 ? 1 : 0) }
        ring.add(body)
        for y in [Float(0.0017), H - 0.0017] {
            ring.add(Prim.torus(major: R - 0.001, minor: 0.0017, segments: seg, sides: detail ? 6 : 4, material: polished), Xform(translation: V3(0, y, 0)))
        }
        for y in [Float(0.0125), H - 0.0125] {
            ring.add(Prim.torus(major: R, minor: 0.0007, segments: seg, sides: 6, minorY: 0.0005, material: polished), Xform(translation: V3(0, y, 0)))
        }
        if detail {
            // Brazed seam strip with a hairline offset.
            let th: Float = 200 * .pi / 180
            ring.add(Prim.roundedBox(V3(0.0026, H - 0.0074, 0.0005), radius: 0.00018, bevelSegments: 1, material: braze),
                     Xform(translation: V3(cos(th) * (R + 0.0001), H / 2, sin(th) * (R + 0.0001)), rotation: simd_quatf(angle: .pi / 2 - th, axis: .up)))
        }
        var m = Model(name: Self.id)
        m.add(ring, Xform(translation: V3(0, R, -H / 2), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        groundAO(&m, height: 0.012)
        return m
    }
}
