import simd
import Foundation

/// Board and batten wall panel, Farmhouse: nine 19 mm pine boards hung vertically with 4 mm gaps, 45 mm
/// battens over every joint, a drip-capped top rail with galvanized flashing and a skirt board. Cut
/// nails on 300 mm centres, paint chipped back to bare pine and rust runs below the nail heads.
public struct BoardAndBattenWallPanel: RealAsset {
    public static let id = "board-and-batten-wall-panel"
    public static let summary = "Board and batten wall panel, 2.0 x 2.4 m: vertical boards, battens, cap rail with flashing, skirt, nails."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 11000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 5.4)

    /// Painted boards and battens.
    public var paint: MaterialKey = "wood.painted-exterior:7F8F78"
    /// Weathered paint on the lower boards.
    public var worn: MaterialKey = "wood.painted-exterior:6F7F69"
    /// Batten and trim paint.
    public var trim: MaterialKey = "wood.painted-exterior:D2D6C6"
    /// Bare wood under chips.
    public var bare: MaterialKey = "wood.weathered"
    /// Nail heads and flashing.
    public var nail: MaterialKey = "metal.galvanized"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 2.0, H: Float = 2.4
        let n = 9, bt: Float = 0.019, gap: Float = 0.004, batW: Float = 0.045
        let pitch = (W - 0.0) / Float(n)
        let bw = pitch - gap
        let y0: Float = 0.14, y1: Float = 2.3         // boards run between the skirt and the cap rail
        for i in 0..<n {
            var r = rng.fork(i)
            let x = -W / 2 + (Float(i) + 0.5) * pitch
            let len = y1 - y0 + r.float(-0.002...0.002)
            let mat: MaterialKey = i == 6 ? "wood.pine-aged" : (r.chance(0.35) ? worn : paint)
            FA.box(&m, V3(bw, len, bt), V3(x, (y0 + y1) / 2, bt / 2), mat, r: 0.0025, rot: FA.q(r.float(-0.25...0.25), FA.Z))
            // Shrinkage check on a board.
            if r.chance(0.4) {
                FJ.slab(&m, V3(0.0015, r.float(0.15...0.4), 0.0016), V3(x + r.float(-0.04...0.04), r.float(0.5...1.8), bt + 0.0003), bare)
            }
        }
        // Battens centred on each joint, plus half battens at the two edges.
        for i in 0...n {
            var r = rng.fork(100 + i)
            let x = -W / 2 + Float(i) * pitch
            let half = i == 0 || i == n
            let w = half ? batW / 2 + 0.002 : batW
            let cx = half ? (i == 0 ? x + w / 2 : x - w / 2) : x
            let mat: MaterialKey = trim
            FA.box(&m, V3(w, y1 - y0 - 0.012, bt), V3(cx, (y0 + y1) / 2, bt + bt / 2 - 0.0005), mat, r: 0.003)
            var y = y0 + 0.15 + r.float(0...0.05)
            while y < y1 - 0.08 {
                let nx = half ? cx : x
                FA.cylZ(&m, r: 0.0048, h: 0.0022, at: V3(nx, y, 2 * bt - 0.0005), nail, bevel: 0.0005, segments: 6)
                if r.chance(0.4) {
                    FJ.slab(&m, V3(0.0035, r.float(0.06...0.2), 0.0006), V3(nx, y - 0.06, 2 * bt + 0.0003), "metal.rust")
                }
                y += 0.3
            }
        }
        // Skirt board with a drip kerf, and the cap rail with a sloped top and galvanized Z-flashing.
        FA.run(&m, [V2(0, 0), V2(0.04, 0), V2(0.04, 0.012), V2(0.034, 0.016), V2(0.034, 0.138), V2(0, 0.138)], length: W, paint, bevel: 0.0015)
        let cap: [V2] = [V2(0, y1), V2(0.036, y1), V2(0.036, y1 + 0.03), V2(0.046, y1 + 0.03), V2(0.046, y1 + 0.04), V2(0.0, H)]
        FA.run(&m, [V2(0, 2.3), V2(0.036, 2.3), V2(0.034, 2.33), V2(0.04, 2.33), V2(0.04, 2.345), V2(0.02, 2.37), V2(0, 2.37)], length: W, worn, bevel: 0.0015)
        _ = cap
        FA.run(&m, [V2(0, 2.37), V2(0.038, 2.372), V2(0.04, 2.368), V2(0.04, 2.35), V2(0.038, 2.35), V2(0.038, 2.366), V2(0, 2.366)], length: W, at: V3(0, 0.028, 0), nail, bevel: 0.0004)
        // Paint flaking back to bare wood, worst low on the boards where splash and ground damp reach.
        for _ in 0..<16 {
            let low = rng.float(0...1)
            let fy = 0.2 + low * low * 1.4
            m.add(Prim.superellipsoid(V3(rng.float(0.035...0.09), rng.float(0.03...0.12), 0.0015), exponent: 2.8, subdivisions: 3, material: bare),
                  Xform(translation: V3(rng.float(-0.95...0.95), fy, bt + 0.0005), rotation: FA.q(rng.float(-12...12), FA.Z)))
        }
        // Paint chips on the lower boards where splashback reaches.
        var spots: [V3] = []
        for _ in 0..<10 { spots.append(V3(rng.float(-0.95...0.95), rng.float(0.18...1.1) * rng.float(0.5...1.0), 0)) }
        FJ.chips(&m, spots: spots, face: bt, bare, rng: &rng, each: 3)
        // Water stain at the skirt line.
        groundAO(&m, height: 0.3, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
