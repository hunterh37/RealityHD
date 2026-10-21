import simd
import Foundation

/// Chalky flint soil tile, 2 x 2 m: thin pale rendzina of the chalk downs after ploughing, with low
/// furrow undulation, white chalk lumps turned up by the share and nodular flints, black where
/// fractured and coated in a white chalky cortex, plus a few sharp knapped shards.
public struct ChalkyFlintSoil: RealAsset {
    public static let id = "chalky-flint-soil"
    public static let summary = "Chalky flint soil tile, 2 x 2 m: thin pale downland soil over chalk, strewn with white chalk lumps and nodular flints with white cortex."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Chalk lumps.
    public var chalkCount: Int = 150
    /// Flint nodules (cortex coated).
    public var flintCount: Int = 90
    /// Broken flint shards showing the black interior.
    public var shardCount: Int = 60
    /// Furrow spacing (m).
    public var furrow: Float = 0.3
    /// Pale soil.
    public var soil: MaterialKey = "rock.limestone:ABA394"
    /// Chalk.
    public var chalk: MaterialKey = "rock.limestone:E8E4D8"
    /// Flint cortex.
    public var cortex: MaterialKey = "rock.limestone:D6CFBE"
    /// Fractured flint interior.
    public var flint: MaterialKey = "rock.slate:26272A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2, base: Float = 0.055
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        func h(_ p: V2) -> Float {
            let f = 0.012 * sin(p.y / furrow * 2 * .pi + 0.4 * Noise.fbm(V3(p.x, 0, p.y), octaves: 2, seed: sd))
            return f + 0.007 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 3, seed: sd + 1)
                     + 0.003 * Noise.fbm(V3(p.x * 30, 0, p.y * 30), octaves: 2, seed: sd + 2)
        }
        GTK.field(&m, w: size.x, d: size.z, edge: base, segments: 40, soil, uvScale: 1) { h($0) }
        var lite = m
        let surf: (V2) -> Float = { base + h($0) }
        // Fine chalk crumbs plus larger lumps turned up by the plough.
        GTK.stones(&m, &rng, count: chalkCount, hx: hx - 0.03, hz: hz - 0.03, size: 0.012...0.06, flat: 0.5...0.8,
                   keys: [chalk, "rock.limestone:DEDACD", "rock.limestone:F0EDE4"], subdivisions: 1, exponent: 2.2, sink: 0.4, surface: surf)
        // Flint nodules: knobbly, irregular, cortex coated.
        var r1 = rng.fork(77)
        GTK.stones(&m, &r1, count: flintCount, hx: hx - 0.04, hz: hz - 0.04, size: 0.03...0.11, flat: 0.45...0.7,
                   keys: [cortex, "rock.limestone:B5AE9E"], subdivisions: 2, exponent: 2.0, sink: 0.35, surface: surf)
        // Fractured flints: dark glassy angular pieces with a cortex rind on one side.
        for k in 0..<shardCount {
            var r = rng.fork(500 + k)
            let p = V2(r.float(-hx + 0.04...hx - 0.04), r.float(-hz + 0.04...hz - 0.04))
            let len = r.float(0.04...0.09)
            let ss = UInt32(truncatingIfNeeded: r.int(0...100_000))
            var s = Prim.superellipsoid(V3(len, len * r.float(0.45...0.65), len * r.float(0.6...0.85)), exponent: 2.0, subdivisions: 2, material: flint) { d in
                1 + 0.32 * Noise.fbm(d * 1.6, octaves: 2, seed: ss)
            }
            s.uvs = s.positions.map { V2($0.x + 0.5 * $0.y, $0.z) + V2(r.float(0...4), 0) }
            GTK.normalizeTexel(&s)
            s.recomputeNormals(weldSeams: false)
            let yaw = r.float(0...360)
            let rot = simd_quatf(degrees: yaw, axis: .up) * simd_quatf(degrees: r.float(-20...20), axis: V3(1, 0, 0))
            let at = V3(p.x, surf(p) + len * 0.06, p.y)
            m.add(s, Xform(translation: at, rotation: rot))
            // Cortex rind: half shell on one end.
            if r.chance(0.7) {
                var c = Prim.superellipsoid(V3(len * 0.55, len * 0.42, len * 0.75), exponent: 2.2, subdivisions: 1, material: cortex)
                c.recomputeNormals(weldSeams: true)
                m.add(c, Xform(translation: at + rot.act(V3(len * 0.32, 0, 0)), rotation: rot))
            }
        }
        groundAO(&m, height: 0.04, floor: 0.7)
        groundAO(&lite, height: 0.04, floor: 0.7)
        return LODModel(levels: [m, lite], switchDistances: [7])
    }
}
