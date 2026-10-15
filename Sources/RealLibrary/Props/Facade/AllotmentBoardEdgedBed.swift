import simd
import Foundation

/// Allotment board-edged bed: a raised bed framed with reclaimed scaffold boards (225 x 38 mm, with
/// galvanized hoop bands nailed on the ends) screwed to 50 mm square corner stakes, filled with raked
/// loam and planted with a 3 x 3 block of young cabbages, on a trodden soil path tile.
public struct AllotmentBoardEdgedBed: RealAsset {
    public static let id = "allotment-board-edged-bed"
    public static let summary = "Raised allotment bed edged with weathered scaffold boards screwed to square timber corner stakes, filled with raked soil and young cabbages."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.8, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Bed outer size inside the tile (m).
    public var bedWidth: Float = 1.7
    public var bedDepth: Float = 1.5
    /// Scaffold board face height (m).
    public var boardHeight: Float = 0.2
    /// Board material.
    public var boardMaterial: MaterialKey = "wood.weathered"
    /// Cabbage leaf material (tinted stem shader, blue-green).
    public var cabbage: MaterialKey = "plant.stem:34503F"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, bw = bedWidth, bd = bedDepth
        let pathH: Float = 0.02, t: Float = 0.038, bh = boardHeight
        let fillTop = pathH + bh - 0.03
        var m = Model(name: Self.id)
        // Trodden path tile around the bed.
        AK.field(&m, w: w, d: d, base: pathH, segments: 14, material: "ground.dirt:5C4734") { p in
            pathH + 0.006 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 3, seed: sd)
        }
        // Raked fill inside the frame.
        let iw = bw - 2 * t - 0.004, id = bd - 2 * t - 0.004
        func fill(_ p: V2) -> Float {
            let rake = 0.004 * sin(p.y * 2 * .pi / 0.05 + 2 * Noise.fbm(V3(p.x * 3, 0, 0), octaves: 2, seed: sd))
            return fillTop + rake + 0.01 * Noise.fbm(V3(p.x * 5, 0, p.y * 5), octaves: 3, seed: sd + 3)
        }
        m.add(Prim.terrain(size: V2(iw, id), segments: 30, material: AK.soil, height: fill))
        // Boards: long sides run full length, short sides butt between them.
        let y0 = pathH - 0.015
        let hx = bw / 2, hz = bd / 2
        AK.edgeBoard(&m, from: V3(-hx, y0, -hz + t / 2), to: V3(hx, y0, -hz + t / 2), height: bh, outward: V3(0, 0, -1), rng: &rng, material: boardMaterial)
        AK.edgeBoard(&m, from: V3(-hx, y0, hz - t / 2), to: V3(hx, y0, hz - t / 2), height: bh, outward: V3(0, 0, 1), rng: &rng, material: boardMaterial)
        AK.edgeBoard(&m, from: V3(-hx + t / 2, y0, -hz + t + 0.002), to: V3(-hx + t / 2, y0, hz - t - 0.002), height: bh, outward: V3(-1, 0, 0), rng: &rng, material: boardMaterial)
        AK.edgeBoard(&m, from: V3(hx - t / 2, y0, -hz + t + 0.002), to: V3(hx - t / 2, y0, hz - t - 0.002), height: bh, outward: V3(1, 0, 0), rng: &rng, material: boardMaterial)
        // Corner stakes inside the frame, with screws through the board faces.
        let st: Float = 0.05
        let stakeTop = y0 + bh + 0.03
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let c = V2(sx * (hx - t - st / 2 - 0.002), sz * (hz - t - st / 2 - 0.002))
            AK.stake(&m, at: c, top: stakeTop, size: st, rng: &rng)
            for k: Float in [0.3, 0.7] {
                AK.screw(&m, at: V3(c.x, y0 + bh * k, sz * (hz + 0.0005)), normal: V3(0, 0, sz))
                AK.screw(&m, at: V3(sx * (hx + 0.0005), y0 + bh * k, c.y), normal: V3(sx, 0, 0))
            }
        }}
        // Mid-span stakes on the long sides against bowing.
        for sz: Float in [-1, 1] {
            let c = V2(0.05, sz * (hz - t - st / 2 - 0.002))
            AK.stake(&m, at: c, top: y0 + bh - 0.01, size: st, rng: &rng)
            for k: Float in [0.3, 0.7] { AK.screw(&m, at: V3(c.x, y0 + bh * k, sz * (hz + 0.0005)), normal: V3(0, 0, sz)) }
        }
        // Young cabbages: 3 x 3 block, rosettes of cupped wavy leaves round a tight heart.
        for i in 0..<3 { for j in 0..<3 {
            var r = rng.fork(i * 3 + j)
            let c = V2((Float(i) - 1) * 0.45 + r.float(-0.03...0.03), (Float(j) - 1) * 0.4 + r.float(-0.03...0.03))
            let base = V3(c.x, fill(c) - 0.004, c.y)
            let scale = r.float(0.85...1.15)
            let n = 7
            for k in 0..<n {
                let yaw = Float(k) / Float(n) * 2 * .pi + r.float(-0.25...0.25)
                m.add(AK.leaf(base, yaw: yaw, length: 0.16 * scale * r.float(0.85...1.1), width: 0.14 * scale,
                              lean: r.float(0.85...1.0), curl: r.float(0.25...0.5), fold: -0.35, material: cabbage))
            }
            for k in 0..<3 {
                let yaw = Float(k) / 3 * 2 * .pi + 0.4
                m.add(AK.leaf(base, yaw: yaw, length: 0.09 * scale, width: 0.08 * scale, lean: 0.25, curl: -0.6, fold: -0.5,
                              material: "plant.stem:56784E"))
            }
            m.add(Prim.superellipsoid(V3(0.075, 0.06, 0.075) * scale, exponent: 2.3, subdivisions: 2, material: "plant.stem:6A8C62") { d in
                1 + 0.08 * sin(d.x * 9) * sin(d.z * 9) },
                  Xform(translation: base + V3(0, 0.032 * scale, 0)))
            AK.clod(&m, at: c + V2(0.12, -0.1), y: fill(c), size: 0.03, rng: &r)
        }}
        // A few stones and clods kicked onto the path.
        for i in 0..<9 {
            var r = rng.fork(500 + i)
            var p = V2(r.float(-w / 2 + 0.05...w / 2 - 0.05), r.float(-d / 2 + 0.05...d / 2 - 0.05))
            if abs(p.x) < hx + 0.03 && abs(p.y) < hz + 0.03 { p.y = (p.y < 0 ? -1 : 1) * (hz + r.float(0.05...0.2)) }
            if r.chance(0.5) { AK.stone(&m, at: p, y: pathH - 0.004, size: r.float(0.015...0.04), rng: &r) }
            else { AK.clod(&m, at: p, y: pathH - 0.004, size: r.float(0.025...0.05), rng: &r, material: AK.dryClod) }
        }
        // Weeds along the board feet.
        for i in 0..<4 {
            var r = rng.fork(800 + i)
            let along = r.float(-hx + 0.1...hx - 0.1)
            let side: Float = r.chance(0.5) ? -1 : 1
            AK.weed(&m, at: V3(along, pathH - 0.003, side * (hz + 0.015)), height: r.float(0.05...0.1), count: 10, rng: &r)
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: pathH, segments: 10, material: "ground.dirt:5C4734") { _ in pathH }
        lite.add(Prim.roundedBox(V3(bw, bh, bd), radius: 0.004, bevelSegments: 1, material: boardMaterial), Xform(translation: V3(0, y0 + bh / 2, 0)))
        lite.add(Prim.terrain(size: V2(iw, id), segments: 8, material: AK.soil) { _ in fillTop + 0.002 })
        return AK.finish(&m, lite: lite, ao: 0.1)
    }
}
