import simd
import Foundation

/// Range blockhouse, 8 x 6 m: thick board-formed concrete box under a stepped roof slab, three armored view slits
/// on the +X face toward the pad, a painted steel blast door on +Z behind a baffle wall, mushroom roof
/// vents, an antenna mast and a cable conduit. Rust streaks run down from the slit frames.
public struct Blockhouse: RealAsset {
    public static let id = "blockhouse"
    public static let summary = "Range blockhouse, 8 x 6 m: thick concrete box under a stepped roof, armored view slits facing the pad, steel blast door behind a baffle wall, roof vents and antenna."
    public static let tags = ["prop", "aerospace", "outdoor", "concrete", "building"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 14, distance: 1.05)

    /// Footprint (x, z) and wall height in meters.
    public var length: Float = 8
    public var depth: Float = 6
    public var wallHeight: Float = 3.2
    public var concrete: MaterialKey = "concrete.rough"
    public var stain: MaterialKey = "concrete.rough:6E655A"
    public var glass: MaterialKey = "glass.tinted"
    public var door: MaterialKey = "metal.painted:5D6B4F"
    public var steel: MaterialKey = "metal.galvanized"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, detail: true), level(seed: seed, detail: false)], switchDistances: [50])
    }

    func level(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, D = depth, H = wallHeight
        m.add(Prim.roundedBox(V3(L, H, D), radius: 0.12, bevelSegments: detail ? 3 : 1, material: concrete), Xform(translation: V3(0, H / 2, 0)))
        // stepped roof: overhanging slab and a raised blast cap
        m.add(Prim.roundedBox(V3(L + 0.4, 0.7, D + 0.4), radius: 0.18, bevelSegments: detail ? 3 : 1, material: concrete),
              Xform(translation: V3(0, H + 0.33, 0)))
        m.add(Prim.roundedBox(V3(L - 1.6, 0.45, D - 1.6), radius: 0.2, bevelSegments: detail ? 3 : 1, material: concrete),
              Xform(translation: V3(0, H + 0.68 + 0.2, 0)))
        // pour joints: shallow lips every 0.8 m on all four walls
        if detail {
            for y in stride(from: Float(0.8), to: H - 0.5, by: 0.8) {
                m.add(Prim.roundedBox(V3(L + 0.02, 0.025, D + 0.02), radius: 0.006, bevelSegments: 1, material: stain), Xform(translation: V3(0, y, 0)))
            }
        }
        // view slits on +X: steel frame, recessed armored glass, rust streak below
        let slitW: Float = 1.2, slitH: Float = 0.28, sy: Float = 2.0
        for i in 0..<3 {
            let z = (Float(i) - 1) * 1.8
            let fx = L / 2 + 0.01
            m.add(Prim.roundedBox(V3(0.12, slitH + 0.16, slitW + 0.16), radius: 0.015, bevelSegments: 1, material: steel), Xform(translation: V3(fx, sy, z)))
            m.add(Prim.roundedBox(V3(0.02, slitH, slitW), radius: 0.004, bevelSegments: 1, material: glass), Xform(translation: V3(fx + 0.065, sy, z)))
            // hood over the slit
            m.add(Prim.roundedBox(V3(0.35, 0.06, slitW + 0.3), radius: 0.01, bevelSegments: 1, material: steel),
                  Xform(translation: V3(fx + 0.17, sy + slitH / 2 + 0.11, z), rotation: simd_quatf(degrees: -8, axis: V3(0, 0, 1))))
            m.add(Prim.roundedBox(V3(0.006, sy - 0.25, rng.float(0.25...0.5)), radius: 0.002, bevelSegments: 1, material: "metal.rust"),
                  Xform(translation: V3(fx + 0.003, (sy - 0.25) / 2 + 0.1, z + rng.float(-0.3...0.3))))
        }
        // blast door on +Z with hinges and lever, baffle wall in front of it
        let dx: Float = -1.6, dz = D / 2 + 0.01
        m.add(Prim.roundedBox(V3(1.2, 2.2, 0.12), radius: 0.02, bevelSegments: 1, material: door), Xform(translation: V3(dx, 1.12, dz + 0.05)))
        m.add(Prim.roundedBox(V3(1.4, 2.4, 0.06), radius: 0.01, bevelSegments: 1, material: steel), Xform(translation: V3(dx, 1.2, dz)))
        for hy in [Float(0.45), 1.8] {
            m.add(Prim.cylinder(radius: 0.05, height: 0.22, bevel: 0.005, segments: 10, material: steel), Xform(translation: V3(dx - 0.62, hy - 0.11, dz + 0.1)))
        }
        m.add(Prim.tube([V3(dx + 0.4, 1.1, dz + 0.12), V3(dx + 0.4, 1.1, dz + 0.22), V3(dx + 0.15, 1.1, dz + 0.22)], radii: [0.025, 0.025, 0.025],
                        sides: 8, seamTile: 0.2, material: steel), .identity)
        m.add(Prim.roundedBox(V3(2.6, 2.6, 0.5), radius: 0.06, bevelSegments: 2, material: concrete), Xform(translation: V3(dx + 0.3, 1.3, dz + 1.6)))
        m.add(Prim.roundedBox(V3(0.5, 2.6, 1.6), radius: 0.06, bevelSegments: 2, material: concrete), Xform(translation: V3(dx - 1.25, 1.3, dz + 0.8)))
        // roof: mushroom vents, antenna mast, cable conduit down the -X wall
        let roofTop = H + 1.1
        for (x, z) in [(Float(1.6), Float(-1.2)), (-2.2, 0.9)] {
            m.add(Prim.cylinder(radius: 0.12, height: 0.7, bevel: 0.01, segments: 12, material: steel), Xform(translation: V3(x, roofTop - 0.1, z)))
            m.add(Prim.lathe([V2(0.3, 0), V2(0.3, 0.05), V2(0.2, 0.18), V2(0, 0.22)], segments: 16, seamTile: 0.3, material: steel),
                  Xform(translation: V3(x, roofTop + 0.58, z)))
        }
        m.add(Prim.tube([V3(-0.6, roofTop - 0.2, -0.4), V3(-0.6, roofTop + 3.5, -0.4)], radii: [0.04, 0.02], sides: 8, seamTile: 0.3, material: steel), .identity)
        for k in 0..<3 {
            let a = Float(k) / 3 * 2 * .pi
            m.add(Prim.tube([V3(-0.6, roofTop + 2.6, -0.4), V3(-0.6 + cos(a) * 1.8, roofTop - 0.6, -0.4 + sin(a) * 1.4)], radii: [0.005, 0.005],
                            sides: 4, seamTile: 0.2, material: steel), .identity)
        }
        m.add(Prim.tube([V3(-L / 2 - 0.08, 0.05, -1.5), V3(-L / 2 - 0.08, H + 0.3, -1.5), V3(-L / 2 + 0.6, H + 1.1, -1.5)], radii: [0.06, 0.06, 0.06],
                        sides: 10, seamTile: 0.3, material: "metal.galvanized-aged"), .identity)
        groundAO(&m, height: 0.6)
        return m
    }
}
