import simd
import Foundation

/// Allotment polytunnel soil bed: inside a polytunnel, two fine-tilth growing beds either side of a woven
/// black ground-cover path pinned with galvanized U pegs, black drip line running down each bed with
/// emitters, rows of young lettuce, a white plant label and treated board edging.
public struct AllotmentPolytunnelSoilBed: RealAsset {
    public static let id = "allotment-polytunnel-soil-bed"
    public static let summary = "Polytunnel soil bed tile, 2 x 2 m: two fine-tilth beds either side of a woven membrane path, with drip lines and rows of lettuce seedlings."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.8, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.15, 2.0)
    /// Path width (m).
    public var pathWidth: Float = 0.5
    /// Lettuce leaf material.
    public var lettuce: MaterialKey = "plant.stem:6E9E3A"
    /// Membrane material.
    public var membrane: MaterialKey = "fabric.canvas:262624"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = size.x, d = size.z, base: Float = 0.02, pw = pathWidth
        var m = Model(name: Self.id)
        func h(_ p: V2) -> Float {
            let ax = abs(p.x)
            let bed: Float = ax < pw / 2 ? 0 : 0.053 * min(1, (ax - pw / 2) / 0.05)
            return base + bed + 0.004 * Noise.fbm(V3(p.x * 9, 0, p.y * 9), octaves: 3, seed: sd)
        }
        ACK.grid(&m, w: w, d: d, base: base, nx: 40, nz: 16, material: "soil.potting:3B2B1E", h)
        // Woven membrane path.
        var mem = Prim.terrain(size: V2(pw - 0.01, d - 0.004), segments: 10, material: membrane) { p in base + 0.006 + 0.0015 * Noise.fbm(V3(p.x * 8, 0, p.y * 8), octaves: 2, seed: sd + 1) }
        mem.computeTangents()
        m.add(mem)
        // U pegs pinning both membrane edges.
        for sx: Float in [-1, 1] { for k in 0..<4 {
            let z = -0.75 + Float(k) * 0.5
            let x = sx * (pw / 2 - 0.03)
            m.add(Prim.tube([V3(x, base + 0.004, z - 0.02), V3(x, base + 0.01, z - 0.02), V3(x, base + 0.01, z + 0.02), V3(x, base + 0.004, z + 0.02)],
                            radii: [0.002, 0.002, 0.002, 0.002], sides: 5, seamTile: 0.05, material: "metal.galvanized-aged"))
        }}
        // Board edging along the outer bed edges.
        let t: Float = 0.032
        for sx: Float in [-1, 1] {
            ACK.edgeBoard(&m, from: V3(sx * (w / 2 - t / 2), 0.0, -d / 2), to: V3(sx * (w / 2 - t / 2), 0.0, d / 2), height: 0.11, thick: t,
                          outward: V3(sx, 0, 0), rng: &rng, material: "wood.pine-aged")
        }
        // Drip lines down each bed with emitters every 0.3 m.
        for sx: Float in [-1, 1] { for lane: Float in [0.3, 0.62] {
            let x = sx * lane
            let pts = (0...8).map { i -> V3 in let z = -d / 2 + 0.01 + Float(i) / 8 * (d - 0.02); return V3(x + 0.01 * sin(Float(i) * 1.3), h(V2(x, z)) + 0.007, z) }
            m.add(Prim.tube(pts, radii: Array(repeating: 0.0075, count: pts.count), sides: 8, seamTile: 0.1, material: "rubber.tubing:1A1A1A"))
            for k in 0..<6 {
                let z = -0.75 + Float(k) * 0.3
                m.add(Prim.roundedBox(V3(0.012, 0.012, 0.022), radius: 0.003, bevelSegments: 1, material: "plastic.black"),
                      Xform(translation: V3(x + 0.006, h(V2(x, z)) + 0.008, z)))
            }
        }}
        // Lettuce seedlings in rows between the drip lines.
        var count = 0
        for sx: Float in [-1, 1] { for lane: Float in [0.46, 0.78] { for k in 0..<6 {
            var r = rng.fork(count); count += 1
            let c = V2(sx * lane + r.float(-0.015...0.015), -0.78 + Float(k) * 0.31 + r.float(-0.02...0.02))
            let b = V3(c.x, h(c) - 0.002, c.y)
            let s = r.float(0.8...1.1)
            let n = 5
            let mat: MaterialKey = lane > 0.6 ? "food.stem-green:6A2234" : lettuce
            for l in 0..<n {
                let yaw = Float(l) / Float(n) * 2 * .pi + r.float(-0.3...0.3)
                let dir = V3(cos(yaw), r.float(0.25...0.45), sin(yaw))
                m.add(ACK.broadLeaf(b + V3(0, 0.004, 0), dir: dir, length: 0.1 * s, width: 0.085 * s, lobes: 7, lobeDepth: 0.08, ruffle: 0.012, cup: 0.012,
                                    spokes: 8, rings: 2, seed: UInt32(count * 8 + l), material: mat))
            }
            m.add(Prim.superellipsoid(V3(0.05, 0.035, 0.05) * s, exponent: 2.2, subdivisions: 2, material: lane > 0.6 ? "food.stem-green:7E3A2E" : "plant.stem:8DBA4E") { d in
                1 + 0.12 * sin(d.x * 11) * sin(d.z * 11) }, Xform(translation: b + V3(0, 0.014 * s, 0)))
        }}}
        // Plant label pushed into the soil, pencil-written end facing up.
        let lp = V2(0.46, -0.98 + 0.08)
        m.add(Prim.roundedBox(V3(0.018, 0.1, 0.0015), radius: 0.0006, bevelSegments: 1, material: "plastic.white"),
              Xform(translation: V3(lp.x, h(lp) + 0.025, lp.y), rotation: simd_quatf(degrees: 10, axis: V3(1, 0, 0))))
        // Hand trowel left on the path: steel blade with a soil smear, ash handle.
        let tp = V3(-0.08, base + 0.012, 0.35), tq = simd_quatf(degrees: 35, axis: .up)
        m.add(Prim.superellipsoid(V3(0.075, 0.008, 0.14), exponent: 3, subdivisions: 3, material: "metal.galvanized-aged") { d in 1 - 0.35 * max(0, d.z) * max(0, d.z) },
              Xform(translation: tp, rotation: tq))
        m.add(Prim.tube([tp + tq.act(V3(0, 0.004, -0.07)), tp + tq.act(V3(0, 0.02, -0.11))], radii: [0.005, 0.005], sides: 6, seamTile: 0.05, material: "metal.galvanized-aged"))
        m.add(Prim.lathe([V2(0, 0), V2(0.014, 0.004), V2(0.016, 0.06), V2(0.013, 0.11), V2(0, 0.115)], segments: 10, seamTile: 0.3, material: "wood.ash-bat"),
              Xform(translation: tp + tq.act(V3(0, 0.02, -0.11)), rotation: tq * simd_quatf(degrees: -95, axis: V3(1, 0, 0))))
        // Crumbs of soil on the membrane.
        for i in 0..<8 {
            var r = rng.fork(900 + i)
            let p = V2(r.float(-pw / 2 + 0.05...pw / 2 - 0.05), r.float(-0.9...0.9))
            ACK.clod(&m, at: p, y: base + 0.004, size: r.float(0.008...0.02), rng: &r, material: "soil.potting:4A3826", sub: 2)
        }
        var lite = Model(name: Self.id + "-lite")
        ACK.grid(&lite, w: w, d: d, base: base, nx: 20, nz: 4, material: "soil.potting:3B2B1E", h)
        lite.add(mem)
        return ACK.finish(&m, lite: lite, ao: 0.05)
    }
}
