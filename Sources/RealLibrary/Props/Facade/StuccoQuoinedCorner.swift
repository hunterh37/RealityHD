import simd
import Foundation

/// Stucco quoined outside corner, Mediterranean: smooth three-coat stucco on two returns with
/// alternating long and short cast-stone quoins in relief, a weep screed and a sooted plinth band.
public struct StuccoQuoinedCorner: RealAsset {
    public static let id = "stucco-quoined-corner"
    public static let summary = "Stucco quoined outside corner: smooth stucco returns with alternating long-short cast stone quoins, weep screed and plinth band."
    public static let tags = ["prop", "architecture", "facade", "stone", "trim"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 45, elevation: 10, distance: 3.4)

    /// Return length on each face (m).
    public var leg: Float = 0.5
    /// Height (m).
    public var height: Float = 2.4
    /// Stucco finish.
    public var stucco: MaterialKey = "concrete.smooth:DDBB8E"
    /// Quoin stone.
    public var quoin: MaterialKey = "stone.cast-stone"
    /// Plinth band.
    public var plinth: MaterialKey = "stone.limestone-sooted"
    /// Weep screed.
    public var screed: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let c = leg / 2, wall: Float = 0.09, proud: Float = 0.01, plinthH: Float = 0.22
        // stucco returns (front face normal +Z, side face normal +X), corner at (c, c)
        FA.box(&m, V3(leg - 0.002, height - plinthH, wall), V3(0, plinthH + (height - plinthH) / 2, c - wall / 2), stucco, r: 0.006)
        FA.box(&m, V3(wall, height - plinthH, leg - 0.002), V3(c - wall / 2, plinthH + (height - plinthH) / 2, 0), stucco, r: 0.006)
        // plinth band, slightly proud
        FA.box(&m, V3(leg, plinthH - 0.012, wall + 0.008), V3(0, (plinthH - 0.012) / 2, c - wall / 2 + 0.004), plinth, r: 0.008)
        FA.box(&m, V3(wall + 0.008, plinthH - 0.012, leg), V3(c - wall / 2 + 0.004, (plinthH - 0.012) / 2, 0), plinth, r: 0.008)
        // weep screed: galvanized drip strip at the plinth line on both faces
        FA.box(&m, V3(leg, 0.012, 0.012), V3(0, plinthH - 0.006, c + 0.004), screed, r: 0.002)
        FA.box(&m, V3(0.012, 0.012, leg), V3(c + 0.004, plinthH - 0.006, 0), screed, r: 0.002)
        // quoins: long 0.30 / short 0.19 alternating between faces, 12 mm reveals
        let qh: Float = 0.2, joint: Float = 0.014
        var y = plinthH + 0.04
        var i = 0
        while y + qh <= height - 0.02 {
            var r = rng.fork(i)
            let longFront = i % 2 == 0
            let lx: Float = longFront ? 0.30 : 0.19, lz: Float = longFront ? 0.19 : 0.30
            let mat: MaterialKey = r.chance(0.2) ? "stone.limestone-sooted" : quoin
            let cx = c + proud - lx / 2, cz = c + proud - lz / 2
            FA.box(&m, V3(lx, qh, lz), V3(cx + r.float(-0.002...0.002), y + qh / 2, cz), mat, r: 0.009)
            y += qh + joint
            i += 1
        }
        // hairline cracks from the quoin tips into the stucco (raised slivers of dirty stucco)
        for k in 0..<4 {
            var r = rng.fork(100 + k)
            let yy = r.float(0.6...2.0), len = r.float(0.06...0.14), ang = r.float(-35...35)
            FA.box(&m, V3(len, 0.003, 0.002), V3(c - 0.3 - len / 2, yy, c + 0.0006), "concrete.rough:5E5244", r: 0.0008,
                   rot: FA.q(ang, FA.Z))
        }
        // dirt streak below one quoin on the side face
        for k in 0..<3 { FA.box(&m, V3(0.002, 0.45 - Float(k) * 0.1, 0.035 - Float(k) * 0.008), V3(c + 0.0006, 1.15 - Float(k) * 0.05, c - 0.22 - Float(k) * 0.012), "concrete.smooth:A88E6C", r: 0.0006)
            FA.box(&m, V3(0.035 - Float(k) * 0.008, 0.45 - Float(k) * 0.1, 0.002), V3(c - 0.33 + Float(k) * 0.012, 1.0 - Float(k) * 0.05, c + 0.0006), "concrete.smooth:A88E6C", r: 0.0006) }
        groundAO(&m, height: 0.2, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
