import simd
import Foundation

/// Coaster set, 10 x 4 x 10 cm: four square cork coasters (9.2 cm, rounded corners, 9.5 mm thick) stacked a few millimeters
/// off-axis in a stainless caddy with a 1.2 mm sheet rim. The top coaster is the worn one, with a ring stain, and a
/// coaster lower in the stack has a chipped corner.
public struct CoasterSet: RealAsset {
    public static let id = "coaster-set"
    public static let summary = "Coaster set, cork: 4 stacked square cork coasters with rounded corners, holder rim, slightly offset stack, ring stain on top coaster, chipped corner."
    public static let tags = ["prop", "interior", "tableware", "wood", "metal"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.10, 0.04, 0.10)
    /// Coaster edge length in meters.
    public var coaster: Float = 0.092
    /// Coaster thickness in meters.
    public var thickness: Float = 0.0095
    /// Cork.
    public var cork: MaterialKey = "cork.grip"
    /// Worn top cork.
    public var corkWorn: MaterialKey = "cork.grip-worn"
    /// Ring stain.
    public var ringStain: MaterialKey = "cork.grip-worn:4A301C"
    /// Pale halo around the ring stain.
    public var ringHalo: MaterialKey = "cork.grip-worn:8A6A44"
    /// Caddy steel.
    public var steel: MaterialKey = "metal.stainless-smudged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [3])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = size.x, plateT: Float = 0.002, h = coaster / 2
        m.add(Prim.roundedBox(V3(w, plateT, w), radius: 0.0008, bevelSegments: 2, material: steel), Xform(translation: V3(0, plateT / 2, 0)))
        let path = DD1HTable.railPath(w: w - 0.0012, d: w - 0.0012, radius: 0.007, y: plateT - 0.0004, segments: detail ? 5 : 3)
        m.add(DD1HTable.wall(path: path, h: 0.0165, t: 0.0012, radius: 0.0004, material: steel))
        let rounded = Shape2D.roundedRect(coaster, coaster, radius: 0.008, segments: detail ? 5 : 3)
        let chipped = Shape2D.rounded([V2(-h, -h), V2(h, -h), V2(h, h - 0.016), V2(h - 0.004, h - 0.009), V2(h - 0.0095, h - 0.0045), V2(h - 0.017, h), V2(-h, h)],
                                      radius: 0.006, segments: detail ? 4 : 2)
        var topY: Float = 0, topX: Float = 0, topZ: Float = 0
        for k in 0..<4 {
            let jx = rng.float(-0.0016...0.0016), jz = rng.float(-0.0016...0.0016)
            let y = plateT + Float(k) * thickness
            let yaw = rng.float(-1.6...1.6)
            let d = thickness - 0.0003
            let x = Xform(translation: V3(jx, y + d / 2, jz),
                          rotation: simd_quatf(degrees: yaw, axis: .up) * simd_quatf(degrees: -90, axis: V3(1, 0, 0)))
            m.add(Prim.extrude(k == 2 ? chipped : rounded, depth: d, bevel: 0.0012, bevelSegments: 2, material: k == 3 ? corkWorn : cork), x)
            topY = y + d; topX = jx; topZ = jz
        }
        if detail {
            let flat: (Float, Float) -> Float = { _, _ in topY }
            m.add(DD1HTable.ringDecal(center: V2(topX + 0.006, topZ - 0.007), r0: 0.0285, r1: 0.0325, lift: 0.0003, material: ringStain, height: flat))
            m.add(DD1HTable.ringDecal(center: V2(topX + 0.006, topZ - 0.007), r0: 0.0255, r1: 0.0285, lift: 0.0002, material: ringHalo, height: flat))
        }
        groundAO(&m, height: 0.02)
        return m
    }
}
