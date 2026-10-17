import simd
import Foundation

/// Poached paddock mud tile, 2 x 2 m: wet clay loam churned by cattle around a gateway. Cloven hoof
/// prints overlap in the trodden middle, the deeper ones holding brown standing water, dried crust
/// ridges stand between them and trampled grass survives along one margin.
public struct PoachedPaddockMud: RealAsset {
    public static let id = "poached-paddock-mud"
    public static let summary = "Poached paddock mud tile, 2 x 2 m: wet clay loam churned by cattle hooves, water-filled prints and trampled grass remnants at the edges."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.12, 2.0)
    /// Cloven hoof prints pressed into the mud.
    public var prints: Int = 220
    /// Grass tufts surviving at the +Z margin.
    public var tufts: Int = 180
    /// Wet mud surface.
    public var mud: MaterialKey = "ground.mud:3F3125"
    /// Standing water in the prints.
    public var water: MaterialKey = "ground.puddle:4A3C2C"
    /// Trampled grass.
    public var grass: MaterialKey = "grass.lawn"
    /// Dry crusted ridge tops.
    public var crust: MaterialKey = "ground.dirt:8A7458"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2, base: Float = 0.065
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        // Hoof prints: two half-ovals (claws) per print, rim pushed up around them.
        struct Print { var c: V2; var dir: V2; var depth: Float }
        var ps: [Print] = []
        for k in 0..<prints {
            var r = rng.fork(100 + k)
            // Denser toward the trodden centre line (z < 0.4).
            let p = V2(r.float(-hx + 0.08...hx - 0.08), r.float(-hz + 0.08...0.45))
            let a = r.float(-0.6...0.6) + (r.chance(0.5) ? 0 : .pi)
            ps.append(Print(c: p, dir: V2(cos(a + .pi / 2), sin(a + .pi / 2)), depth: r.float(0.02...0.045)))
        }
        func h(_ p: V2) -> Float {
            var y = 0.01 * Noise.fbm(V3(p.x * 1.6, 0, p.y * 1.6), octaves: 3, seed: sd)
            y += 0.004 * Noise.fbm(V3(p.x * 14, 0, p.y * 14), octaves: 2, seed: sd + 1)
            // Margin with grass sits higher and smoother.
            let marg = max(0, min(1, (p.y - 0.45) / 0.25))
            y += 0.012 * marg
            for q in ps where marg < 1 {
                let d = p - q.c
                let along = simd_dot(d, q.dir), side = d.x * q.dir.y - d.y * q.dir.x
                for s: Float in [-1, 1] {
                    let u = along / 0.055, v = (side - s * 0.022) / 0.02
                    let e = u * u + v * v
                    if e < 1 { y -= q.depth * (1 - e) * (1 - marg) }
                    else if e < 2.2 { y += 0.006 * (1 - abs(e - 1.5) / 0.7) * (1 - marg) }
                }
            }
            return min(0.03, max(-0.045, y))
        }
        GTK.field(&m, w: size.x, d: size.z, edge: base, segments: 64, mud, uvScale: 1) { h($0) }
        // Water table: brown standing water shows in the deep prints.
        let z0 = -hz + 0.015, z1: Float = 0.6
        var w = Prim.terrain(size: V2(size.x - 0.03, z1 - z0), segments: 4, material: water) { _ in base - 0.007 }
        w.positions = w.positions.map { $0 + V3(0, 0, (z0 + z1) / 2) }
        w.computeTangents()
        m.add(w)
        var lite = m
        // Dried crust flakes on the ridges between prints.
        GTK.stones(&m, &rng, count: 110, hx: hx - 0.05, hz: 0.4, size: 0.008...0.022, flat: 0.25...0.4, keys: [crust, "ground.dirt:6E5A42"],
                   subdivisions: 1, sink: 0.6, surface: { base + h($0) }, keep: { h($0) > 0.006 })
        // Trampled grass: leaning tufts along the +Z margin, flattened toward the mud.
        var gs = Surface(material: grass)
        for k in 0..<tufts {
            var r = rng.fork(3000 + k)
            var t = PlantKit.Tuft()
            t.count = 10; t.radius = 0.025; t.height = 0.058; t.heightRange = 0.4...1.0
            t.width = 0.003...0.005; t.lean = 0.5...1.1; t.splay = 0.6; t.segments = 2; t.columns = 2
            let x = r.float(-hx + 0.03...hx - 0.03), z = r.float(0.5...hz - 0.03)
            gs.append(PlantKit.tuft(t, at: V3(x, base + h(V2(x, z)), z), rng: &r, material: grass))
        }
        gs.positions = gs.positions.map { V3(min(hx - 0.002, max(-hx + 0.002, $0.x)), $0.y, min(hz - 0.002, $0.z)) }
        gs.recomputeNormals(weldSeams: false)
        m.add(gs)
        PlantKit.finish(&m)
        groundAO(&m, height: 0.04, floor: 0.7)
        groundAO(&lite, height: 0.04, floor: 0.7)
        return LODModel(levels: [m, lite], switchDistances: [8])
    }
}
