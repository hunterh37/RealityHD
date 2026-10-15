import simd
import Foundation

/// Allotment bean cane row bed: a raked double row for runner beans with young plants at each
/// station, a bundle of 2.4 m bamboo canes tied with jute twine waiting on the path, and a row label.
public struct AllotmentBeanCaneRowBed: RealAsset {
    public static let id = "allotment-bean-cane-row-bed"
    public static let summary = "Allotment double row of young runner beans on a raked ridge, with a twine-tied bundle of bamboo canes laid on the path ready for the A-frame."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 34, distance: 2.8, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Distance between the two rows (m).
    public var rowSpacing: Float = 0.6
    /// Bean leaf material.
    public var bean: MaterialKey = "plant.stem:4C7A34"
    /// Cane material.
    public var cane: MaterialKey = "wood.lumber-maple:C8A766"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, pathH: Float = 0.02
        var m = Model(name: Self.id)
        // Bed ridge along X, 1.1 m wide, raked crosswise.
        func ground(_ p: V2) -> Float {
            let t = abs(p.y + 0.1) / 0.55
            let ridge: Float = t < 0.8 ? 1 : AKK.ridge(min(1, (t - 0.8) / 0.2))
            let rake = 0.003 * sin(p.x * 2 * .pi / 0.045)
            return pathH + 0.07 * ridge + rake * ridge + 0.007 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 3, seed: sd)
        }
        AKK.grid(&m, w: w, d: d, base: pathH, nx: 80, nz: 40) { p in
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let k = max(0, min(1, e / 0.06))
            return pathH + (ground(p) - pathH) * k * k * (3 - 2 * k)
        }
        // Stations: 2 rows, 15 cm apart, each with a runner bean seedling.
        for row in 0..<2 {
            let z = -0.1 + (Float(row) - 0.5) * rowSpacing
            for i in 0..<7 {
                var r = rng.fork(row * 10 + i)
                let c = V2((Float(i) - 3) * 0.24 + r.float(-0.015...0.015), z + r.float(-0.015...0.015))
                let g = ground(c)
                let base = V3(c.x, g - 0.004, c.y)
                // Watering dimple ring of darker soil.
                m.add(Prim.terrain(size: V2(0.1, 0.1), segments: 4, material: AKK.clod) { _ in g + 0.0015 }, Xform(translation: V3(c.x, 0, c.y)))
                let hgt = r.float(0.055...0.085)
                let top = base + V3(r.float(-0.01...0.01), hgt, r.float(-0.01...0.01))
                let mid = (base + top) * 0.5 + V3(0.006, 0, 0)
                m.add(Prim.tube([base, mid, top], radii: [0.0028, 0.0025, 0.002], sides: 6, seamTile: 0.02, material: "plant.stem:6B8A3A"))
                // Two heart-shaped seed leaves and a trifoliate first true leaf.
                let yaw = r.float(0...6.28)
                for s: Float in [-1, 1] {
                    let dir = V3(cos(yaw) * s, 0.25, sin(yaw) * s)
                    m.add(AKK.leaflet(top - V3(0, 0.012, 0), dir: dir, length: 0.065, width: 0.058, cup: 0.25, material: bean))
                }
                for k in 0..<3 {
                    let a = yaw + 1.57 + Float(k - 1) * 0.9
                    m.add(AKK.leaflet(top, dir: V3(cos(a), 0.55, sin(a)), length: 0.075, width: 0.055, cup: 0.2, material: "plant.stem:5A8A3E"))
                }
            }
        }
        // Bundle of bamboo canes on the path, tied twice with jute twine.
        let bz: Float = 0.78, by = pathH + 0.012
        var canes: [V2] = []
        for i in 0..<11 {
            let a = Float(i) * 2.399, r = 0.028 * sqrt(Float(i) / 11)
            canes.append(V2(r * cos(a), r * sin(a)))
        }
        for (i, o) in canes.enumerated() {
            var r = rng.fork(200 + i)
            let x0: Float = -0.93 + r.float(0...0.04), x1: Float = 0.93 - r.float(0...0.04)
            let rad = r.float(0.008...0.011)
            let p0 = V3(x0, by + 0.028 + o.y, bz + o.x), p1 = V3(x1, by + 0.028 + o.y * 0.9, bz + o.x * 0.9)
            m.add(Prim.tube([p0, (p0 + p1) * 0.5, p1], radii: [rad, rad * 0.92, rad * 0.8], sides: 8, seamTile: 0.04, material: cane))
            var x = x0 + 0.1
            while x < x1 - 0.05 {
                let f = (x - x0) / (x1 - x0)
                let c = p0 + (p1 - p0) * f
                m.add(Prim.torus(major: rad * (1 - 0.2 * f), minor: 0.0022, segments: 8, sides: 4, material: "wood.lumber-maple:B08F52"),
                      Xform(translation: c, rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
                x += r.float(0.4...0.5)
            }
        }
        for tx: Float in [-0.45, 0.4] {
            for k in 0..<3 {
                m.add(Prim.torus(major: 0.042, minor: 0.0022, segments: 16, sides: 4, material: "fabric.burlap:9C7A4A"),
                      Xform(translation: V3(tx + Float(k) * 0.005, by + 0.028, bz), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            }
        }
        // Row label at the west end.
        var lr = rng.fork(300)
        let lp = V2(-0.88, -0.1 - rowSpacing / 2)
        m.add(Prim.roundedBox(V3(0.02, 0.13, 0.003), radius: 0.001, bevelSegments: 1, material: "plastic.white"),
              Xform(translation: V3(lp.x, ground(lp) + 0.03, lp.y), rotation: simd_quatf(degrees: lr.float(-8...8), axis: V3(0, 0, 1))))
        // Path stones and a few weeds.
        for i in 0..<8 {
            var r = rng.fork(400 + i)
            let p = V2(r.float(-0.95...0.95), r.chance(0.5) ? r.float(0.55...0.68) : r.float(-0.95...(-0.72)))
            if r.chance(0.6) { AKK.stone(&m, at: p, y: pathH - 0.003, size: r.float(0.015...0.035), rng: &r) }
            else { AKK.weed(&m, at: V3(p.x, pathH - 0.002, p.y), height: r.float(0.04...0.08), count: 8, rng: &r) }
        }
        var lite = Model(name: Self.id + "-lite")
        AKK.field(&lite, w: w, d: d, base: pathH, segments: 12) { p in ground(p) }
        return AKK.finish(&m, lite: lite, ao: 0.06)
    }
}
