import simd
import Foundation

/// Allotment raised sleeper bed: two courses of reclaimed oak railway sleepers (200 x 120 mm) laid on
/// edge with bonded corners, fixed with timber screws, filled with dark loam and planted with lettuces.
public struct AllotmentRaisedSleeperBed: RealAsset {
    public static let id = "allotment-raised-sleeper-bed"
    public static let summary = "Raised allotment bed of two courses of reclaimed oak railway sleepers with bonded corners and timber screws, filled with loam and lettuces."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 2.8, studio: true)

    /// Outer footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 1.2
    /// Sleeper section: face height and thickness (m).
    public var sleeperHeight: Float = 0.2
    public var sleeperThick: Float = 0.12
    /// Sleeper material (tarred oak).
    public var sleeper: MaterialKey = "wood.oak:4E3D2B"
    /// Lettuce leaf material.
    public var lettuce: MaterialKey = "plant.stem:6E9A3E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, h = sleeperHeight, t = sleeperThick
        let hx = w / 2, hz = d / 2
        var m = Model(name: Self.id)
        func sleeperRun(_ a: V3, _ b: V3, out: V3, _ r: inout SeededRNG) {
            let mid = V3(0, h / 2, 0)
            let (s, x) = RealLibrary.board(from: a + mid, to: b + mid, width: h - 0.004, thick: t, up: out, bevel: 0.009, material: sleeper)
            var xf = x
            xf.rotation = xf.rotation * simd_quatf(degrees: r.float(-0.8...0.8), axis: V3(1, 0, 0))
            m.add(s, xf)
            // Old spike holes where the chairs were bolted, on the top face.
            let dir = simd_normalize(b - a), len = simd_length(b - a)
            for k: Float in [0.22, 0.78] where r.chance(0.7) {
                let p = a + dir * len * k + V3(0, h - 0.001, 0)
                m.add(Prim.cylinder(radius: 0.011, height: 0.004, bevel: 0.001, segments: 10, material: "wood.endgrain-weathered"),
                      Xform(translation: p))
            }
        }
        // Course 1: long sides full length; course 2: short sides full depth (bonded corners).
        for course in 0..<2 {
            var r = rng.fork(10 + course)
            let y = Float(course) * h
            if course == 0 {
                sleeperRun(V3(-hx, y, -hz + t / 2), V3(hx, y, -hz + t / 2), out: V3(0, 0, -1), &r)
                sleeperRun(V3(-hx, y, hz - t / 2), V3(hx, y, hz - t / 2), out: V3(0, 0, 1), &r)
                sleeperRun(V3(-hx + t / 2, y, -hz + t + 0.003), V3(-hx + t / 2, y, hz - t - 0.003), out: V3(-1, 0, 0), &r)
                sleeperRun(V3(hx - t / 2, y, -hz + t + 0.003), V3(hx - t / 2, y, hz - t - 0.003), out: V3(1, 0, 0), &r)
            } else {
                sleeperRun(V3(-hx + t / 2, y, -hz), V3(-hx + t / 2, y, hz), out: V3(-1, 0, 0), &r)
                sleeperRun(V3(hx - t / 2, y, -hz), V3(hx - t / 2, y, hz), out: V3(1, 0, 0), &r)
                sleeperRun(V3(-hx + t + 0.003, y, -hz + t / 2), V3(hx - t - 0.003, y, -hz + t / 2), out: V3(0, 0, -1), &r)
                sleeperRun(V3(-hx + t + 0.003, y, hz - t / 2), V3(hx - t - 0.003, y, hz - t / 2), out: V3(0, 0, 1), &r)
            }
        }
        // Timber screws through the top course into the bottom one at the corners.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            for k: Float in [0.35, 0.75] {
                rivet(&m, at: V3(sx * (hx - t / 2), 2 * h + 0.0005, sz * (hz - t * k)), normal: .up, radius: 0.009, height: 0.003, material: "metal.screw-zinc")
            }
            AKK.screw(&m, at: V3(sx * (hx - t * 0.5), h * 0.5, sz * (hz + 0.0005)), normal: V3(0, 0, sz))
            AKK.screw(&m, at: V3(sx * (hx + 0.0005), h * 1.5, sz * (hz - t * 0.5)), normal: V3(sx, 0, 0))
        }}
        // Loam fill, a little below the top edge, with spade-turned lumps.
        let iw = w - 2 * t - 0.006, id = d - 2 * t - 0.006
        let fillTop = 2 * h - 0.04
        func fill(_ p: V2) -> Float {
            fillTop + 0.012 * Noise.fbm(V3(p.x * 5, 0, p.y * 5), octaves: 4, seed: sd)
        }
        m.add(Prim.terrain(size: V2(iw, id), segments: 34, material: AKK.soil, height: fill))
        // Lettuces in two rows of four: butterhead rosettes.
        for i in 0..<4 { for j in 0..<2 {
            var r = rng.fork(100 + i * 2 + j)
            let c = V2((Float(i) - 1.5) * 0.4 + r.float(-0.03...0.03), (Float(j) - 0.5) * 0.42 + r.float(-0.03...0.03))
            let base = V3(c.x, fill(c) - 0.004, c.y)
            let s = r.float(1.25...1.5)
            for k in 0..<9 {
                let yaw = Float(k) / 9 * 2 * .pi + r.float(-0.2...0.2)
                m.add(AKK.leaf(base, yaw: yaw, length: 0.12 * s, width: 0.11 * s, lean: r.float(0.75...0.95), curl: r.float(0.3...0.5),
                               fold: -0.3, material: lettuce))
            }
            for k in 0..<4 {
                m.add(AKK.leaf(base, yaw: Float(k) * 1.57 + 0.5, length: 0.07 * s, width: 0.07 * s, lean: 0.3, curl: -0.5, fold: -0.5,
                               material: "plant.stem:8DB653"))
            }
            if r.chance(0.5) { AKK.clod(&m, at: c + V2(0.1, 0.09), y: fill(c), size: 0.025, rng: &r) }
        }}
        // Weeds at the sleeper feet and a trowel-dropped stone on the rim.
        for i in 0..<5 {
            var r = rng.fork(300 + i)
            let side: Float = r.chance(0.5) ? -1 : 1
            AKK.weed(&m, at: V3(r.float(-hx + 0.25...hx - 0.25), 2 * h - 0.03, side * (hz - t - 0.05)), height: r.float(0.05...0.1), count: 10, rng: &r)
        }
        var rs = rng.fork(400)
        AKK.stone(&m, at: V2(0.55, -hz + t / 2), y: 2 * h, size: 0.035, rng: &rs)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(w, 2 * h, d), radius: 0.008, bevelSegments: 1, material: sleeper), Xform(translation: V3(0, h, 0)))
        lite.add(Prim.terrain(size: V2(iw, id), segments: 6, material: AKK.soil) { _ in 2 * h + 0.001 })
        return AKK.finish(&m, lite: lite, ao: 0.1)
    }
}
