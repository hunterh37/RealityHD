import simd
import Foundation

/// Gravel reinforced grass grid tile, 2 x 2 m: black recycled-HDPE honeycomb cellular grid, 40 mm
/// deep with 3 mm walls, filled with 6-10 mm pea gravel over a compacted sub-base. Grass breaks
/// through the cells away from a wheel rut, where the gravel is pushed out and the cell rims show.
public struct GravelReinforcedGrassGrid: RealAsset {
    public static let id = "gravel-reinforced-grass-grid"
    public static let summary = "Gravel reinforced grass grid tile, 2 x 2 m: black HDPE honeycomb cells filled with pea gravel, grass breaking through, with a wheel rut."
    public static let tags = ["prop", "architecture", "facade", "ground", "concrete"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Honeycomb cell circumradius (m).
    public var cellRadius: Float = 0.07
    /// Cell wall thickness (m).
    public var wallThickness: Float = 0.004
    /// Cell depth (m).
    public var cellDepth: Float = 0.04
    /// Grid material.
    public var grid: MaterialKey = "plastic.matte:1E1E1E"
    /// Gravel fill.
    public var gravel: MaterialKey = "ground.gravel"
    /// Grass blades.
    public var grass: MaterialKey = "grass.lawn"
    /// Sub-base.
    public var subBase: MaterialKey = "soil.sod"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2, base: Float = 0.02, wallTop = base + cellDepth
        let rutX = rng.float(-0.45...(-0.25)), sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        func rut(_ p: V2) -> Float { exp(-pow((p.x - rutX) / 0.13, 2)) }
        func fill(_ p: V2) -> Float {
            wallTop - 0.011 - 0.012 * rut(p) + 0.006 * exp(-pow((abs(p.x - rutX) - 0.17) / 0.05, 2)) + 0.003 * Noise.fbm(V3(p.x * 8, 0, p.y * 8), octaves: 2, seed: sd)
        }
        // Honeycomb walls: flat-top hexagons, three edges per cell so shared edges are built once.
        var walls = Surface(material: grid)
        let R = cellRadius, t = wallThickness / 2
        func wall(_ a: V2, _ b: V2, _ h0: Float, _ h1: Float) {
            let d = simd_normalize(b - a), n = V2(-d.y, d.x) * t, c: Float = 0.0015
            let quads: [[V3]] = [
                [V3(a.x + n.x, h0, a.y + n.y), V3(b.x + n.x, h0, b.y + n.y), V3(b.x + n.x, h1 - c, b.y + n.y), V3(a.x + n.x, h1 - c, a.y + n.y)],
                [V3(b.x - n.x, h0, b.y - n.y), V3(a.x - n.x, h0, a.y - n.y), V3(a.x - n.x, h1 - c, a.y - n.y), V3(b.x - n.x, h1 - c, b.y - n.y)],
                [V3(a.x + n.x, h1 - c, a.y + n.y), V3(b.x + n.x, h1 - c, b.y + n.y), V3(b.x, h1, b.y), V3(a.x, h1, a.y)],
                [V3(a.x, h1, a.y), V3(b.x, h1, b.y), V3(b.x - n.x, h1 - c, b.y - n.y), V3(a.x - n.x, h1 - c, a.y - n.y)],
            ]
            for q in quads {
                let i = UInt32(walls.positions.count)
                let nn = simd_normalize(simd_cross(q[1] - q[0], q[3] - q[0]))
                let len = simd_length(b - a)
                walls.add(q[0], nn, V2(0, q[0].y)); walls.add(q[1], nn, V2(len, q[1].y))
                walls.add(q[2], nn, V2(len, q[2].y + 0.01)); walls.add(q[3], nn, V2(0, q[3].y + 0.01))
                walls.quad(i, i + 3, i + 2, i + 1)
            }
        }
        let dz = sqrt(Float(3)) * R
        let ni = Int(size.x / (1.5 * R)) + 2, nj = Int(size.z / dz) + 2
        for i in -1...ni { for j in -1...nj {
            let c = V2(-hx + Float(i) * 1.5 * R, -hz + (Float(j) + (i % 2 == 0 ? 0 : 0.5)) * dz)
            let corner = { (k: Int) -> V2 in let a = Float(k) * .pi / 3; return c + V2(cos(a), sin(a)) * R }
            for k in 0..<3 {
                var a = corner(k), b = corner(k + 1)
                // Clip the edge to the tile.
                let lo = V2(-hx + 0.003, -hz + 0.003), hi = V2(hx - 0.003, hz - 0.003)
                if (a.x < lo.x && b.x < lo.x) || (a.x > hi.x && b.x > hi.x) || (a.y < lo.y && b.y < lo.y) || (a.y > hi.y && b.y > hi.y) { continue }
                a = simd_clamp(a, lo, hi); b = simd_clamp(b, lo, hi)
                guard simd_length(b - a) > 0.01 else { continue }
                let mid = (a + b) / 2
                let sag: Float = rut(mid) > 0.5 && rng.chance(0.3) ? 0.004 : 0
                wall(a, b, base, wallTop - sag)
            }
        }}
        walls.computeTangents()
        m.add(walls)
        // Gravel fill and sub-base.
        GTK.field(&m, w: size.x - 0.004, d: size.z - 0.004, edge: wallTop - 0.011, segments: 30, gravel, uvScale: 2.5) { p in fill(p) - (wallTop - 0.011) }
        GK.slab(&m, w: size.x - 0.004, d: size.z - 0.004, h: base + 0.002, subBase, r: 0.002)
        // Geotextile membrane under the grid, its cut edge turned up a little at the tile border.
        for sd2: Float in [-1, 1] {
            GK.box(&m, V3(sd2 * (hx - 0.004), base + 0.012, 0), V3(0.0016, 0.024, size.z - 0.01), "fabric.canvas:2A2A28", r: 0.0005)
            GK.box(&m, V3(0, base + 0.012, sd2 * (hz - 0.004)), V3(size.x - 0.01, 0.024, 0.0016), "fabric.canvas:2A2A28", r: 0.0005)
        }
        GK.box(&m, V3(0, base + 0.003, 0), V3(size.x - 0.006, 0.0016, size.z - 0.006), "fabric.canvas:2A2A28", r: 0.0005)
        var lite = m
        var keepRng = rng.fork(77)
        // Loose pea gravel kicked onto the rims, mostly along the rut.
        GTK.stones(&m, &rng, count: 55, hx: hx - 0.03, hz: hz - 0.03, size: 0.008...0.016, flat: 0.55...0.8,
                   keys: ["rock.river:9A9184", "rock.river:B5AC9C", "rock.river:7D756A", "rock.river:A6927A"], subdivisions: 1, exponent: 2.2, sink: 0.4,
                   surface: { fill($0) + 0.001 }, keep: { p in keepRng.chance(0.3 + 0.7 * rut(p)) })
        // Grass growing through the cells, thinning to nothing in the rut.
        var blades = Surface(material: grass), dry = Surface(material: "grass.dry")
        for k in 0..<140 {
            var r = rng.fork(2000 + k)
            let p = V2(r.float(-(hx - 0.06)...(hx - 0.06)), r.float(-(hz - 0.06)...(hz - 0.06)))
            let wild = 0.5 + 0.5 * Noise.fbm(V3(p.x * 2.2, 0, p.y * 2.2), octaves: 2, seed: sd + 9)
            guard rut(p) < 0.25, r.chance(0.35 + 0.65 * wild) else { continue }
            var tf = PlantKit.Tuft()
            tf.count = r.int(24...34); tf.height = r.float(0.042...0.05); tf.heightRange = 0.6...1; tf.radius = 0.04
            tf.segments = 1; tf.width = 0.005...0.008; tf.lean = 0.1...0.4
            if r.chance(0.25) { dry.append(PlantKit.tuft(tf, at: V3(p.x, fill(p) - 0.003, p.y), rng: &r, material: "grass.dry")) }
            else { blades.append(PlantKit.tuft(tf, at: V3(p.x, fill(p) - 0.003, p.y), rng: &r, material: grass)) }
        }
        m.add(blades); m.add(dry)
        // Tyre track: compacted, oil-darkened gravel down the middle of the rut.
        var track = Prim.terrain(size: V2(0.14, size.z - 0.02), segments: 24, material: "ground.gravel:6E6A62") { q in fill(V2(q.x + rutX, q.y)) + 0.0012 }
        track.uvs = track.uvs.map { $0 * 2.5 }; track.computeTangents()
        m.add(track, Xform(translation: V3(rutX, 0, 0)))
        return GTK.finish(&m, &lite, ao: 0.05, switchAt: 8)
    }
}
