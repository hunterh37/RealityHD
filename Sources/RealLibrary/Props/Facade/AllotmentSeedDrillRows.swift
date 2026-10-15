import simd
import Foundation

/// Allotment seed drill rows: a raked seedbed with fine rake tine lines, five hoe-drawn drills at
/// 30 cm spacing, seedlings (paired cotyledons) up in three drills, the newest drill still open
/// under a garden line strung taut between two pointed pegs, and white plastic row labels.
public struct AllotmentSeedDrillRows: RealAsset {
    public static let id = "allotment-seed-drill-rows"
    public static let summary = "Raked seedbed with shallow seed drills, string line between two pegs, seedlings emerging in rows and row-end labels."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Number of drills and their spacing (m).
    public var drills: Int = 6
    public var spacing: Float = 0.28
    /// Drill depth (m).
    public var drillDepth: Float = 0.03
    /// Seedling leaf material (tinted stem shader).
    public var seedling: MaterialKey = "plant.stem:4E7A2C"
    /// Garden line material.
    public var line: MaterialKey = "sack.jute"
    /// Raked tilth material.
    public var tilth: MaterialKey = "ground.dirt:4E3A28"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, base: Float = 0.05
        let z0 = -Float(drills - 1) * spacing / 2
        func h(_ p: V2) -> Float {
            let u = (p.y - z0) / spacing
            let k = (u - u.rounded()) * spacing // metres from nearest drill line
            let wob = 0.006 * Noise.fbm(V3(p.x * 2, 0, 0), octaves: 2, seed: sd)
            let inBed = u.rounded() >= 0 && u.rounded() <= Float(drills - 1) && abs(p.x) < w / 2 - 0.12
            let drill: Float = inBed ? -drillDepth * max(0, 1 - pow(abs(k + wob) / 0.04, 2)) : 0
            let lip: Float = inBed ? 0.007 * max(0, 1 - pow((abs(k + wob) - 0.05) / 0.015, 2)) : 0
            let rake = 0.004 * sin(p.y * 2 * .pi / 0.055 + 3 * Noise.fbm(V3(p.x * 1.5, 0, 0), octaves: 2, seed: sd + 1))
            let tilth = 0.006 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 4, seed: sd + 2) + 0.003 * Noise.ridged(V3(p.x * 30, 0, p.y * 30), octaves: 2, seed: sd + 3)
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let f = max(0, min(1, (e - 0.04) / 0.08))
            return base + (drill + lip + rake + tilth + 0.006) * f
        }
        var m = Model(name: Self.id)
        AK.grid(&m, w: w, d: d, base: base, nx: 28, nz: 116, material: tilth, h)
        // Seedlings in drills 0, 1 and 3 (2 just sown, 4 open under the line).
        for (row, n) in [(0, 28), (1, 26), (2, 22), (4, 16)] {
            let zc = z0 + Float(row) * spacing
            for i in 0..<n {
                var r = rng.fork(row * 1000 + i)
                let x = -w / 2 + 0.18 + (Float(i) + r.float(-0.3...0.3)) * (w - 0.36) / Float(n - 1)
                let p = V2(x, zc + r.float(-0.006...0.006))
                let root = V3(p.x, h(p) - 0.002, p.y)
                let sc = r.float(1.7...2.3) * (row == 4 ? 0.7 : 1)
                let stemTop = root + V3(0, 0.025 * sc, 0)
                m.add(PlantKit.stem([root, root + V3(0.001, 0.013 * sc, 0), stemTop], radius: 0.0012, tipRadius: 0.001, sides: 3,
                                    weight: V2(0, 1), phase: 0, material: "plant.stem:7C8A4A"))
                let yaw = r.float(0...(2 * .pi))
                for s: Float in [0, .pi] {
                    let dir = V3(cos(yaw + s), 0.35, sin(yaw + s))
                    m.add(AK.leaflet(stemTop, dir: dir, length: 0.018 * sc, width: 0.011 * sc, cup: 0.3, material: seedling))
                }
            }
        }
        // Garden line over the open drill: two pointed pegs and a taut twine.
        let lz = z0 + Float(drills - 1) * spacing
        let pegX = w / 2 - 0.07
        let pegTop = base + 0.095
        for sx: Float in [-1, 1] {
            var r = rng.fork(9000 + Int(sx + 1))
            let px = sx * pegX
            m.add(Prim.roundedBox(V3(0.025, pegTop - base + 0.03, 0.025), radius: 0.003, bevelSegments: 1, material: "wood.pine-aged"),
                  Xform(translation: V3(px, (pegTop + base - 0.03) / 2, lz), rotation: simd_quatf(degrees: r.float(-6...6), axis: V3(0, 0, 1))))
            // Line wound round the peg.
            m.add(Prim.torus(major: 0.016, minor: 0.0025, segments: 12, sides: 4, material: line), Xform(translation: V3(px, pegTop - 0.03, lz)))
            m.add(Prim.torus(major: 0.016, minor: 0.0025, segments: 12, sides: 4, material: line), Xform(translation: V3(px, pegTop - 0.036, lz)))
        }
        let lineY = pegTop - 0.033
        m.add(Prim.tube([V3(-pegX + 0.016, lineY, lz), V3(0, lineY - 0.004, lz), V3(pegX - 0.016, lineY, lz)], radii: [0.0012, 0.0012, 0.0012],
                        sides: 4, seamTile: 0.05, material: line, capEnd: true))
        // Row labels at the west end of each sown drill.
        for row in 0..<drills - 1 {
            var r = rng.fork(9500 + row)
            let zc = z0 + Float(row) * spacing + 0.035
            let x = -w / 2 + 0.1
            let tilt = simd_quatf(degrees: r.float(-10...10), axis: V3(1, 0, 0)) * simd_quatf(degrees: r.float(-8...8), axis: V3(0, 0, 1))
            m.add(Prim.extrude(Shape2D.rounded([V2(-0.009, 0), V2(0.009, 0), V2(0.009, 0.1), V2(0, 0.112), V2(-0.009, 0.1)], radius: 0.002),
                               depth: 0.0015, bevel: 0.0004, bevelSegments: 1, material: "plastic.white"),
                  Xform(translation: V3(x, base - 0.03, zc), rotation: simd_quatf(degrees: 90, axis: .up) * tilt))
            // Pencilled writing as a grey strip near the top.
            m.add(Prim.roundedBox(V3(0.0004, 0.03, 0.011), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:6A6A6A"),
                  Xform(translation: V3(x + 0.001, base + 0.045, zc), rotation: tilt))
        }
        // A few stones raked to the margin.
        for i in 0..<18 {
            var r = rng.fork(12000 + i)
            let side: Float = r.chance(0.5) ? -1 : 1
            let p = V2(side * r.float(w / 2 - 0.1...w / 2 - 0.04), r.float(-d / 2 + 0.05...d / 2 - 0.05))
            AK.stone(&m, at: p, y: h(p) - 0.003, size: r.float(0.012...0.03), rng: &r)
        }
        for i in 0..<24 {
            var r = rng.fork(13000 + i)
            let p = V2(r.float(-w / 2 + 0.06...w / 2 - 0.06), r.float(-d / 2 + 0.06...d / 2 - 0.06))
            AK.clod(&m, at: p, y: h(p) - 0.002, size: r.float(0.012...0.025), rng: &r)
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 36, material: tilth, h)
        return AK.finish(&m, lite: lite, ao: 0.06)
    }
}
