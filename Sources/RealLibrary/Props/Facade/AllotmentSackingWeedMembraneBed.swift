import simd
import Foundation

/// Allotment bed under weed-control cover: black woven polypropylene membrane laid over the soil with
/// a folded hem, two strips of old hessian coffee sacking overlapping it, 150 mm galvanized U-pins
/// holding the seams, bricks weighting the loose edge, cross-cut planting holes with courgette
/// seedlings, and couch grass escaping at the margins.
public struct AllotmentSackingWeedMembraneBed: RealAsset {
    public static let id = "allotment-sacking-weed-membrane-bed"
    public static let summary = "Bed under black woven weed membrane and hessian sacking, U-pinned, brick-weighted, courgettes planted through cross-cut holes."
    public static let tags = ["prop", "architecture", "facade", "ground", "fabric"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.8, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.08, 2.0)
    /// Membrane material (woven polypropylene).
    public var membrane: MaterialKey = "rubber.floor-mat:202120"
    /// Sacking material.
    public var sacking: MaterialKey = "fabric.burlap:8A6E4A"
    /// Pin material.
    public var pin: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = size.x, d = size.z, base: Float = 0.01
        func soilH(_ p: V2) -> Float { base + 0.008 * Noise.fbm(V3(p.x * 4, 0, p.y * 4), octaves: 3, seed: sd) }
        var m = Model(name: Self.id)
        AK.field(&m, w: w, d: d, base: base, segments: 16, material: "ground.dirt:4E3A28", soilH)
        // Membrane: drapes over clods (lumps) with long shallow wrinkles.
        let mw: Float = 1.82, md: Float = 1.7, mz: Float = 0.05
        func memH(_ p: V2) -> Float {
            let lump = 0.008 * max(0, Noise.fbm(V3(p.x * 7, 0, p.y * 7), octaves: 2, seed: sd + 2))
            let wr = 0.004 * sin(p.x * 23 + 3 * Noise.fbm(V3(0, 0, p.y * 2), octaves: 2, seed: sd + 3))
            return soilH(p) + 0.006 + lump + wr
        }
        var mem = Prim.terrain(size: V2(mw, md), segments: 44, material: membrane) { p in memH(V2(p.x, p.y + mz)) }
        mem.positions = mem.positions.map { $0 + V3(0, 0, mz) }
        mem.computeTangents()
        m.add(mem)
        // Folded hem: rolled membrane edge along the front.
        let hz = mz - md / 2
        let hem = catmull((0...8).map { i -> V3 in let x = -mw / 2 + mw * Float(i) / 8; return V3(x, memH(V2(x, hz)) + 0.006, hz) }, per: 4)
        m.add(Prim.tube(hem, radii: Array(repeating: 0.009, count: hem.count), sides: 6, seamTile: 0.1, material: membrane))
        // Hessian sacking strips overlapping the membrane on the right, frayed hem.
        for (i, (x, wid)) in [(Float(0.55), Float(0.55)), (Float(-0.6), Float(0.45))].enumerated() {
            var r = rng.fork(20 + i)
            let len: Float = i == 0 ? 1.55 : 0.8, z0: Float = i == 0 ? 0.05 : 0.35
            let rot = r.float(-0.05...0.05)
            var s = Prim.terrain(size: V2(wid, len), segments: 20, material: sacking) { p in
                let q = V2(p.x * cos(rot) - p.y * sin(rot) + x, p.x * sin(rot) + p.y * cos(rot) + z0)
                return memH(q) + 0.012 + 0.016 * max(0, sin(p.y * 9 + Float(i) + 2 * p.x)) + 0.005 * sin(p.x * 17 + p.y * 3) + 0.004 * Noise.fbm(V3(p.x * 20, 0, p.y * 20), octaves: 2, seed: sd + 9)
            }
            s.positions = s.positions.map { p in V3(p.x * cos(rot) - p.z * sin(rot) + x, p.y, p.x * sin(rot) + p.z * cos(rot) + z0) }
            s.computeTangents()
            m.add(s)
            // Frayed weft threads at the ends.
            for e: Float in [-1, 1] { for k in 0..<10 {
                let u = (Float(k) / 9 - 0.5) * wid * 0.9
                let lx = u, lz = e * len / 2
                let px = lx * cos(rot) - lz * sin(rot) + x, pz = lx * sin(rot) + lz * cos(rot) + z0
                let y = memH(V2(px, pz)) + 0.006
                m.add(Prim.tube([V3(px, y, pz), V3(px + r.float(-0.01...0.01), y - 0.002, pz + e * r.float(0.015...0.035))], radii: [0.0012, 0.0008], sides: 3, seamTile: 0.05, material: sacking))
            }}
        }
        // Soil washed onto the membrane and dark damp patches on the sacking.
        for i in 0..<9 {
            var r = rng.fork(150 + i)
            let p = V2(r.float(-0.85...0.15), r.float(-0.75...0.85))
            let rad = r.float(0.05...0.12)
            var s = Prim.terrain(size: V2(rad * 2, rad * 1.4), segments: 6, material: "ground.mud:4A3828") { q in
                let f = max(0, 1 - simd_length(V2(q.x / rad, q.y / (rad * 0.7))))
                return memH(V2(p.x + q.x, p.y + q.y)) + 0.0015 + 0.002 * f - (f < 0.05 ? 0.004 : 0)
            }
            s.positions = s.positions.map { $0 + V3(p.x, 0, p.y) }
            m.add(s)
        }
        // U-pins along the seams.
        for i in 0..<14 {
            var r = rng.fork(100 + i)
            let p: V2
            if i < 6 { p = V2(-mw / 2 + 0.06 + Float(i) * (mw - 0.12) / 5, hz + 0.03) }
            else if i < 10 { p = V2(0.55 + (i % 2 == 0 ? -0.24 : 0.24), -0.6 + Float(i - 6) * 0.45) }
            else { p = V2(-mw / 2 + 0.04, -0.6 + Float(i - 10) * 0.45) }
            let y = memH(p) + 0.012
            let yaw = r.float(0...3.14)
            let a = V3(cos(yaw), 0, sin(yaw)) * 0.03
            let c = V3(p.x, y, p.y)
            let pinPath = catmull([c - a + V3(0, -0.012, 0), c - a, c - a * 0.6 + V3(0, 0.004, 0), c + a * 0.6 + V3(0, 0.004, 0), c + a, c + a + V3(0, -0.012, 0)], per: 3)
            m.add(Prim.tube(pinPath, radii: Array(repeating: 0.0026, count: pinPath.count), sides: 5, seamTile: 0.05, material: r.chance(0.3) ? "metal.rust" : pin))
        }
        // Bricks weighting the back edge, one broken half.
        for i in 0..<4 {
            var r = rng.fork(200 + i)
            let p = V2(-0.75 + Float(i) * 0.5 + r.float(-0.05...0.05), mz + md / 2 - 0.06)
            let half = i == 2
            m.add(Prim.roundedBox(V3(half ? 0.11 : 0.215, 0.065, 0.1025), radius: 0.004, bevelSegments: 2, material: "brick.common:9A5A44"),
                  Xform(translation: V3(p.x, memH(p) + 0.027, p.y), rotation: simd_quatf(degrees: r.float(-15...15), axis: .up) * simd_quatf(degrees: r.float(-3...3), axis: V3(1, 0, 0))))
        }
        // Cross-cut planting holes: soil disc, four folded-back flaps, courgette seedling.
        for i in 0..<6 {
            var r = rng.fork(300 + i)
            let p = V2(-0.65 + Float(i % 3) * 0.5 + r.float(-0.03...0.03), -0.35 + Float(i / 3) * 0.6 + r.float(-0.03...0.03))
            if p.x > 0.25 { continue }
            let y = memH(p)
            m.add(Prim.terrain(size: V2(0.13, 0.13), segments: 4, material: "soil.potting:3E2C1E") { q in y + 0.0015 + 0.003 * max(0, 1 - simd_length(q) * 14) },
                  Xform(translation: V3(p.x, 0, p.y), rotation: simd_quatf(degrees: 45, axis: .up)))
            for k in 0..<4 {
                let a = Float(k) * 1.5708 + 0.785
                let dir = V3(cos(a), 0, sin(a))
                m.add(AK.leaflet(V3(p.x, y + 0.003, p.y) + dir * 0.065, dir: -dir * 0.6 + V3(0, 0.5, 0), length: 0.05, width: 0.05, cup: 0, material: membrane))
            }
            let root = V3(p.x, y + 0.006, p.y)
            for k in 0..<5 {
                let yaw = Float(k) * 1.2566 + r.float(-0.2...0.2)
                m.add(AK.leaf(root, yaw: yaw, length: 0.12 * r.float(0.85...1.05), width: 0.13, lean: 1.0, curl: 0.25, fold: -0.2, segments: 4, material: "plant.stem:3F6A2A"))
            }
        }
        // Couch grass at the uncovered margins and the soil edge clods.
        for i in 0..<18 {
            var r = rng.fork(500 + i)
            let p: V2 = i % 2 == 0 ? V2(r.float(-0.92...0.92), r.float(-0.94...(hz - 0.03))) : V2((r.chance(0.5) ? -1 : 1) * r.float(0.92...0.94), r.float(-0.9...0.9))
            if i % 3 == 0 { AK.clod(&m, at: p, y: soilH(p) - 0.004, size: r.float(0.02...0.035), rng: &r) }
            else { AK.weed(&m, at: V3(p.x, soilH(p) - 0.002, p.y), height: r.float(0.035...0.05), count: 14, rng: &r) }
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 6, material: "ground.dirt:4E3A28") { _ in base }
        var lm = Prim.terrain(size: V2(mw, md), segments: 6, material: membrane) { _ in base + 0.01 }
        lm.positions = lm.positions.map { $0 + V3(0, 0, mz) }
        lite.add(lm)
        return AK.finish(&m, lite: lite, ao: 0.05)
    }
}
