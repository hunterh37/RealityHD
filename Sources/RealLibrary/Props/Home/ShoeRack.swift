import simd
import Foundation

/// Slatted shoe rack, 1.0 x 0.35 m and 0.48 m high: three shelves of light bamboo-look slats (slightly uneven widths and tone) resting on side rails of a matte black steel tube frame with end caps, a rear cross brace with a diagonal, a top handle rail and rubber feet. Lightly scuffed; front is +Z.
public struct ShoeRack: RealAsset {
    public static let id = "shoe-rack"
    public static let summary = "Three-tier shoe rack, 1 m: bamboo slat shelves on a black steel tube frame with rubber feet."
    public static let tags = ["prop", "floorplan", "home", "furniture", "wood", "metal", "interior"]
    public static let budget = 13_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 1.7, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.0, 0.48, 0.35)
    /// Number of slatted shelves.
    public var shelves = 3
    /// Slat material.
    public var slat: MaterialKey = "wood.lumber-maple"
    /// Frame tube powder coat.
    public var frame: MaterialKey = "metal.powdercoat:26272A"
    /// Feet and end caps.
    public var rubber: MaterialKey = "plastic.matte:151515"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = size.x, h = size.y, d = size.z
        let r: Float = 0.011, sides = detail ? 12 : 7
        let px = w / 2 - r, pz = d / 2 - r
        let foot: Float = 0.014
        func tube(_ a: V3, _ b: V3, _ rad: Float = 0.0095) {
            m.add(Prim.tube([a, b], radii: [rad, rad], sides: sides, seamTile: 0.1, material: frame, capEnd: true))
        }
        func cap(_ p: V3, up: Bool) {
            m.add(Prim.cylinder(radius: r + 0.0006, height: 0.008, bevel: 0.0025, segments: detail ? 14 : 8, material: rubber),
                  Xform(translation: p + V3(0, up ? 0 : -0.008, 0)))
        }
        // Posts with rubber feet below and caps above.
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                tube(V3(sx * px, foot, sz * pz), V3(sx * px, h - 0.008, sz * pz), r)
                m.add(Prim.cylinder(radius: r + 0.001, height: foot, bevel: 0.003, segments: detail ? 14 : 8, material: rubber),
                      Xform(translation: V3(sx * px, 0, sz * pz)))
                cap(V3(sx * px, h - 0.008, sz * pz), up: true)
            }
        }
        // Shelves: side rails along Z, slats along X.
        let slatT: Float = 0.012
        let levels: [Float] = (0..<shelves).map { 0.075 + Float($0) * (0.385 - 0.075) / Float(max(shelves - 1, 1)) }
        let n = 7, gap: Float = 0.009
        let slatSpan = d - 2 * r - 0.006
        let baseW = (slatSpan - Float(n - 1) * gap) / Float(n)
        for (li, top) in levels.enumerated() {
            let railY = top - slatT - 0.008
            for sx: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.022, 0.016, d - 2 * r + 0.002), radius: 0.003, bevelSegments: 2, material: frame),
                      Xform(translation: V3(sx * (px - 0.001), railY, 0)))
            }
            // Slats: width wobble keeps the total span fixed.
            var widths = (0..<n).map { _ in baseW * rng.float(0.92...1.08) }
            let sum = widths.reduce(0, +)
            widths = widths.map { $0 * (slatSpan - Float(n - 1) * gap) / sum }
            var z = -slatSpan / 2
            let slatLen = 2 * (px - r - 0.001) - 0.002 + 0.02
            for i in 0..<n {
                let wd = widths[i]
                let tone: MaterialKey = (li * n + i) % 6 == 4 ? "wood.lumber-pine" : (li == 0 && i % 2 == 1 ? "wood.pine-aged" : slat)
                m.add(plank(slatLen, wd, slatT, bevel: 0.0035, material: tone),
                      Xform(translation: V3(rng.float(-0.002...0.002), top - slatT / 2, z + wd / 2)))
                z += wd + gap
            }
        }
        // Top handle rails along Z, joined by bent corners to the post caps.
        for sx: Float in [-1, 1] {
            tube(V3(sx * px, h - 0.03, -pz), V3(sx * px, h - 0.03, pz), 0.008)
        }
        // Rear cross braces and a diagonal.
        tube(V3(-px, levels[0] - 0.035, -pz), V3(px, levels[0] - 0.035, -pz), 0.008)
        tube(V3(-px, h - 0.06, -pz), V3(px, h - 0.06, -pz), 0.008)
        tube(V3(-px, levels[0] - 0.035, -pz), V3(px, h - 0.06, -pz + 0.0), 0.006)
        // Front low stretcher at each side between posts above the feet.
        for sx: Float in [-1, 1] { tube(V3(sx * px, 0.04, -pz), V3(sx * px, 0.04, pz), 0.008) }
        // Bare-steel chips on the post bases.
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] where detail {
                m.add(Prim.cylinder(radius: r + 0.0004, height: 0.012, bevel: 0.0008, segments: 10, material: "metal.steel"),
                      Xform(translation: V3(sx * px, foot + 0.004, sz * pz)))
            }
        }
        // Scuffs: lighter nicks on the front edge of the top slat and bare-metal chips on a rail.
        for _ in 0..<(detail ? 3 : 0) {
            m.add(Prim.roundedBox(V3(rng.float(0.02...0.05), 0.0006, 0.004), radius: 0.0002, bevelSegments: 1, material: "wood.bench-maple"),
                  Xform(translation: V3(rng.float(-0.35...0.35), levels[0] + 0.0003, pz - 0.009)))
        }
        groundAO(&m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        return m
    }
}
