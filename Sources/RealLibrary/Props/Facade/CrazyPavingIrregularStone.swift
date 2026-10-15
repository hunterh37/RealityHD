import simd
import Foundation

/// Crazy paving tile, 2 x 2 m: broken sandstone and limestone pieces of every shape laid
/// jigsaw-fashion with 10-25 mm earth joints, chipped edges, mixed tones, moss cushions and grit in
/// the joints, on a bedding of soil. Arts and Crafts garden path idiom.
public struct CrazyPavingIrregularStone: RealAsset {
    public static let id = "crazy-paving-irregular-stone"
    public static let summary = "Crazy paving tile, 2 x 2 m: irregular broken stone pieces laid jigsaw-fashion with wide earth joints and moss."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Number of stone pieces.
    public var pieces: Int = 48
    /// Stone thickness (m).
    public var thickness: Float = 0.05
    /// Half joint width range (m).
    public var halfJoint: ClosedRange<Float> = 0.005...0.012
    /// Stone materials and tones.
    public var stones: [MaterialKey] = ["stone.sandstone:B9A47F", "stone.sandstone:A08B6A", "stone.limestone:BFB6A2", "stone.sandstone:8F8068", "stone.limestone:A9A08C"]
    /// Joint soil.
    public var soil: MaterialKey = "ground.dirt"
    /// Number of moss cushions in the joints.
    public var mossTufts: Int = 30
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y, hx = size.x / 2, hz = size.z / 2
        // Jittered grid seeds for even piece sizes, Voronoi cells by half-plane clipping.
        let side = Int(Float(pieces).squareRoot().rounded())
        var seeds: [V2] = []
        for j in 0..<side { for i in 0..<side {
            let cx = -hx + (Float(i) + 0.5) * size.x / Float(side), cz = -hz + (Float(j) + 0.5) * size.z / Float(side)
            seeds.append(V2(cx + rng.float(-0.4...0.4) * size.x / Float(side), cz + rng.float(-0.4...0.4) * size.z / Float(side)))
        }}
        var edgePts: [V2] = []
        for (i, s) in seeds.enumerated() {
            var cell: [V2] = [V2(-hx, -hz), V2(hx, -hz), V2(hx, hz), V2(-hx, hz)]
            for (j, t) in seeds.enumerated() where j != i {
                let mid = (s + t) / 2, n = simd_normalize(t - s)
                cell = FPK.clipHalf(cell, o: mid, n: n)
                if cell.count < 3 { break }
            }
            var poly = FPK.inset(cell, rng.float(halfJoint))
            guard poly.count >= 3 else { continue }
            // Chip the edges: insert a jittered midpoint on long edges.
            var chipped: [V2] = []
            for k in 0..<poly.count {
                let a = poly[k], b = poly[(k + 1) % poly.count]
                chipped.append(a)
                if simd_distance(a, b) > 0.12 {
                    let e = simd_normalize(b - a), nIn = V2(-e.y, e.x)
                    chipped.append((a + b) / 2 + nIn * rng.float(0...0.008) + e * rng.float(-0.02...0.02))
                }
            }
            poly = chipped
            edgePts.append(contentsOf: poly)
            let mat = rng.pick(stones)
            FPK.piece(&m, poly, top: top + rng.float(-0.003...0.003), thick: thickness * rng.float(0.85...1.15), bevel: 0.006, mat, tilt: 0.9, rng: &rng)
        }
        for k in 0..<mossTufts {
            var rr = rng.fork(1000 + k)
            guard let p = edgePts.randomElement(using: &rr) else { break }
            FPK.moss(&m, at: p, y: top - 0.008, len: rr.float(0.025...0.06), alongX: rr.chance(0.5))
        }
        GK.slab(&m, w: size.x - 0.004, d: size.z - 0.004, h: top - 0.018, soil, r: 0.003)
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, top, size.z), radius: 0.004, bevelSegments: 1, material: "stone.sandstone"), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
