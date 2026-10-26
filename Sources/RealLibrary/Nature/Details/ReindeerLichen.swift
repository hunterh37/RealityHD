import simd
import Foundation

/// 30 cm patch of reindeer lichen: 7 to 10 tufts of repeatedly forking grey-white hollow stalks. 2 LODs.
public struct ReindeerLichen: RealAsset {
    public static let id = "reindeer-lichen"
    public static let summary = "Reindeer lichen patch, 30 cm: tufts of finely forking grey-white stalks with pale green tint; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 13_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 0.6)
    public init() {}

    static func branch(_ s: inout Model, _ rng: inout SeededRNG, p: V3, d: V3, len: Float, r: Float, depth: Int, sides: Int, mat: MaterialKey) {
        var pts = [p]
        var cur = p, dir = d
        for _ in 0..<3 {
            dir = simd_normalize(dir + V3(rng.float(-0.25...0.25), rng.float(-0.1...0.12), rng.float(-0.25...0.25)))
            cur += dir * len / 3
            pts.append(cur)
        }
        s.add(DetailKit24.wire(pts, r0: r, r1: r * 0.6, sides: sides, material: mat, weight: 3, cap: true))
        if depth == 0 { return }
        let kids = 2
        for _ in 0..<kids {
            let side = simd_normalize(V3(rng.float(-1...1), rng.float(0.2...0.9), rng.float(-1...1)))
            let nd = simd_normalize(dir * 0.8 + side * 0.6)
            branch(&s, &rng, p: cur, d: nd, len: len * 0.7, r: r * 0.7, depth: depth - 1, sides: sides, mat: mat)
        }
    }

    public func build(seed: UInt64) -> LODModel {
        DetailKit24.lods(SeededRNG(seed: seed), dist: 3) { lod, rng in
            var m = Model(name: Self.id)
            m.add(DetailKit24.blob(V3(0, 0.0005, 0), V3(0.15, 0.0015, 0.14), sub: 3, material: "moss.cushion:6E7A55"))
            let tufts = rng.int(7...10)
            for _ in 0..<tufts {
                let c = rng.inDisc(radius: 0.11)
                let tint = ["D9DCCB", "CBD2BC", "E4E4D6", "C2CCAE"][rng.int(0...3)]
                let mat = MaterialKey("moss.cushion:\(tint)")
                let stalks = rng.int(lod == 0 ? 3...4 : 2...3)
                for _ in 0..<stalks {
                    let o = rng.inDisc(radius: 0.02)
                    let d = simd_normalize(V3(rng.float(-0.5...0.5), 1, rng.float(-0.5...0.5)))
                    var local = rng.fork(rng.int(0...9999))
                    Self.branch(&m, &local, p: V3(c.x + o.x, 0.0, c.y + o.y), d: d, len: rng.float(0.025...0.04),
                                r: 0.0021, depth: lod == 0 ? 3 : 2, sides: 3, mat: mat)
                }
            }
            return m
        }
    }
}
