import simd
import Foundation

/// Clapboard lap siding run: architectural facade customizer, New England Colonial. Parts: tapered bevel clapboards, 4 in exposure, staggered scarf butt joints, starter strip kicking out the first course, outside corner board with bead, nail heads at 16 in stud spacing, drip cap at the top, paint wear and checking near the base.
public struct ClapboardLapSidingRun: RealAsset {
    public static let id = "clapboard-lap-siding-run"
    public static let summary = "Clapboard lap siding run, 1.2 x 1.2 m: beveled clapboards at 4 in exposure with scarf-jointed butt joints, a corner board and nail heads at each stud line."
    public static let tags = ["prop", "architecture", "facade", "wood", "trim"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 2.4)

    /// Run width in meters.
    public var width: Float = 1.2
    /// Run height in meters.
    public var height: Float = 1.2
    /// Clapboard exposure (4 in).
    public var exposure: Float = 0.1
    /// Clapboard paint tint, sRGB hex.
    public var paintTint: String = "64727B"
    /// Corner board and cap paint tint, sRGB hex.
    public var trimTint: String = "E2DDD0"
    /// Sheathing material.
    public var sheathing: MaterialKey = "wood.plywood"
    /// Nail material.
    public var nail: MaterialKey = "metal.cast-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, tS: Float = 0.004
        let boardH: Float = 0.14, tButt: Float = 0.018, tTop: Float = 0.004
        let paint = "wood.painted-exterior:" + paintTint, worn = "wood.painted-shaker-worn:" + paintTint
        let trim = "wood.painted-exterior:" + trimTint
        CLAD.backer(&m, w: W, h: H, t: tS, face: sheathing, edge: "wood.plywood-edge")
        // Outside corner board (5/4 x 4) with a quirk bead on its inner edge.
        let cw: Float = 0.11, ct: Float = 0.019
        CLAD.beadedCasing(&m, x: -W / 2 + cw / 2, z: tS, w: cw, h: H, t: ct, beadSide: 1, trim)
        // Drip cap over the top course.
        let capH: Float = 0.04
        FA.side(&m, [V2(0, 0), V2(0.022, 0.002), V2(0.024, 0.01), V2(0.006, capH), V2(0, capH)],
                thick: W - cw, at: V3(cw / 2, H - capH, tS), trim, bevel: 0.0015)
        let x0 = -W / 2 + cw + 0.001, x1 = W / 2
        // Water table: plain base board with a beveled drip cap; clapboards start above it.
        let wt: Float = 0.13
        FA.box(&m, V3(x1 - x0, wt - 0.02, 0.018), V3((x0 + x1) / 2, (wt - 0.02) / 2, tS + 0.009), "wood.painted-shaker-worn:" + trimTint, r: 0.003)
        FA.side(&m, [V2(0, 0), V2(0.024, 0), V2(0.024, 0.005), V2(0.004, 0.022), V2(0, 0.022)], thick: x1 - x0,
                at: V3((x0 + x1) / 2, wt - 0.022, tS), trim, bevel: 0.0015)
        for x in stride(from: x0 + 0.06, to: x1, by: 0.406) { CLAD.cutNail(&m, at: V3(x, wt * 0.45, tS + 0.018), nail) }
        // Starter strip kicks the first course out.
        FA.box(&m, V3(x1 - x0, 0.03, 0.007), V3((x0 + x1) / 2, wt + 0.016, tS + 0.0035), "wood.endgrain-weathered", r: 0.001)
        let studs = stride(from: x0 + 0.06, to: x1, by: 0.406).map { $0 }
        var k = 0
        while true {
            let yb = wt + Float(k) * exposure
            if yb > H - capH - 0.02 { break }
            let len = min(boardH, H - capH + 0.01 - yb)
            let standoff: Float = k == 0 ? 0.008 : (tButt - tTop) * (boardH - exposure) / boardH + tTop
            let tilt = atan(standoff / len) * 180 / .pi
            // Random board lengths; joints staggered and broken over studs.
            var x = x0
            var seg = 0
            while x < x1 - 0.01 {
                var r = rng.fork(k * 31 + seg)
                var l = r.float(0.5...1.4)
                if seg == 0 && k % 2 == 1 { l = r.float(0.25...0.6) }
                var end = min(x + l, x1)
                if let s = studs.min(by: { abs($0 - end) < abs($1 - end) }), end < x1 - 0.05 { end = s }
                if end - x < 0.15 { end = min(x1, x + 0.4) }
                let o = Shape2D.rounded([V2(0, 0), V2(end - x - 0.0015, 0), V2(end - x - 0.0015, len), V2(0, len)], radius: 0.002, segments: 1)
                let low = k < 3
                var mat = (low && r.chance(0.7)) || r.chance(0.25) ? worn : paint
                if r.chance(0.3) { mat = (mat == worn ? "wood.painted-shaker-worn:" : "wood.painted-exterior:") + "5E6C74" }
                if k == 4 && seg == 0 { mat = "wood.lumber-pine" }
                if k < 2 && r.chance(0.35) { mat = "wood.weathered" }   // paint failed in the splash zone   // unpainted replacement board
                let piece = CLAD.taperedPiece(o, thick: { p in tTop + (tButt - tTop) * max(0, 1 - p.y / boardH) }, bevel: 0.0018, material: mat)
                m.add(piece, Xform(translation: V3(x, yb, tS + standoff), rotation: FA.q(-tilt, FA.X) * FA.q(r.float(-0.04...0.04), FA.Z)))
                for s in studs where s > x + 0.02 && s < end - 0.02 {
                    CLAD.cutNail(&m, at: V3(s + r.float(-0.004...0.004), yb + 0.02, tS + standoff + tButt - 0.004), nail, size: 0.005)
                }
                x = end; seg += 1
            }
            k += 1
        }
        groundAO(&m, height: 0.12, floor: 0.75)
        return LODModel(FC.place(m))
    }
}
