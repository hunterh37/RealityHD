import simd
import Foundation

/// Allotment gravel edged path: a 2 m square tile with a 0.7 m pea-gravel walk running its full
/// depth between scaffold-board edgings (galvanized hoop bands, square stakes, zinc screws), with
/// soil bed margins either side, loose stones kicked onto the boards and weeds in the gravel.
public struct AllotmentGravelEdgedPath: RealAsset {
    public static let id = "allotment-gravel-edged-path"
    public static let summary = "2 m square allotment path tile: a compacted gravel walk between scaffold-board edgings with galvanized bands and stakes, soil beds either side."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "wood", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 32, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Gravel path width between boards (m).
    public var pathWidth: Float = 0.7
    /// Edging board height (m).
    public var boardHeight: Float = 0.09
    /// Gravel surface material.
    public var gravel: MaterialKey = "ground.gravel:8A8072"
    /// Edging board material.
    public var boardMaterial: MaterialKey = "wood.weathered"
    /// Bed soil.
    public var soil: MaterialKey = "ground.dirt:4A3725"
    /// Loose pebbles on the path surface.
    public var pebbles: Int = 120
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, t: Float = 0.038
        let base: Float = 0.03
        let px = pathWidth / 2
        let bx = px + t / 2
        // Soil beds outside the boards, up against them; gravel inside sits a little higher.
        func soilH(_ p: V2) -> Float {
            let e = d / 2 - abs(p.y)
            let f = max(0, min(1, (e - 0.04) / 0.08))
            let lump = 0.012 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 4, seed: sd) + 0.004 * Noise.ridged(V3(p.x * 25, 0, p.y * 25), octaves: 2, seed: sd + 1)
            let toBoard = max(0, 1 - (abs(p.x) - bx - t / 2) / 0.12)
            return base + (lump + 0.012 + 0.012 * toBoard) * f * max(0, min(1, (w / 2 - abs(p.x) - 0.04) / 0.08))
        }
        func gravelH(_ p: V2) -> Float {
            // Crowned path, worn in a wheel-barrow rut down the middle.
            let c = 1 - pow(p.x / px, 2)
            let rut = -0.006 * exp(-pow((p.x - 0.12) / 0.06, 2))
            let g = 0.004 * Noise.fbm(V3(p.x * 14, 0, p.y * 14), octaves: 3, seed: sd + 2)
            return base + 0.03 + 0.008 * c + rut + g
        }
        var m = Model(name: Self.id)
        for sx: Float in [-1, 1] {
            let bw = w / 2 - bx - t / 2 + 0.004
            let cx = sx * (bx + t / 2 - 0.002 + bw / 2)
            var s = Prim.terrain(size: V2(bw, d), segments: 22, material: soil) { q in soilH(V2(q.x + cx, q.y)) }
            s.uvs = s.positions.map { V2($0.x + cx, $0.z) }
            s.computeTangents()
            m.add(s, Xform(translation: V3(cx, 0, 0)))
            // Outer skirt walls keep the tile edge closed.
            GK.box(&m, V3(sx * (w / 2 - 0.005), base / 2, 0), V3(0.01, base, d), soil, r: 0.001)
            GK.box(&m, V3(cx, base / 2, -d / 2 + 0.005), V3(bw, base, 0.01), soil, r: 0.001)
            GK.box(&m, V3(cx, base / 2, d / 2 - 0.005), V3(bw, base, 0.01), soil, r: 0.001)
        }
        do {
            let gw = pathWidth + 0.004
            var s = Prim.terrain(size: V2(gw, d), segments: 30, material: gravel) { q in gravelH(q) }
            s.computeTangents()
            m.add(s)
            GK.box(&m, V3(0, (base + 0.03) / 2, -d / 2 + 0.005), V3(gw, base + 0.03, 0.01), gravel, r: 0.001)
            GK.box(&m, V3(0, (base + 0.03) / 2, d / 2 - 0.005), V3(gw, base + 0.03, 0.01), gravel, r: 0.001)
        }
        // Scaffold boards: two lengths per side butting near the middle, banded ends.
        let y0 = base - 0.02
        for sx: Float in [-1, 1] {
            var r = rng.fork(100 + Int(sx + 1))
            let split: Float = 0
            AK.edgeBoard(&m, from: V3(sx * bx, y0, -d / 2 + 0.002), to: V3(sx * bx, y0, d / 2 - 0.002), height: boardHeight,
                         outward: V3(sx, 0, 0), rng: &r, material: boardMaterial)
            // Stakes on the bed side at the joint and quarter points, screwed through.
            for z in [-d / 2 + 0.25, split, d / 2 - 0.25] {
                let c = V2(sx * (bx + t / 2 + 0.027), z)
                AK.stake(&m, at: c, top: y0 + boardHeight - 0.012, size: 0.05, rng: &r)
                for k: Float in [0.5] {
                    AK.screw(&m, at: V3(sx * (bx - t / 2 - 0.0005), y0 + boardHeight * k, z), normal: V3(-sx, 0, 0))
                }
            }
        }
        // Loose pea gravel and flints on the path, thickest against the boards.
        for i in 0..<pebbles {
            var r = rng.fork(1000 + i)
            let edge = r.chance(0.4)
            let x = edge ? (r.chance(0.5) ? -1 : 1) * r.float(px - 0.07...px - 0.01) : r.float(-px + 0.01...px - 0.01)
            let p = V2(x, r.float(-d / 2 + 0.02...d / 2 - 0.02))
            let s = r.float(0.008...0.02)
            let sz = V3(s * r.float(0.9...1.3), s * r.float(0.55...0.8), s * r.float(0.8...1.1))
            let mat: MaterialKey = r.pick(["rock.river", "rock.river:B5A58A", "rock.granite-weathered", "rock.river:6E625A"])
            m.add(Prim.superellipsoid(sz, exponent: r.float(2.2...2.8), subdivisions: 1, material: mat),
                  Xform(translation: V3(p.x, gravelH(p) - sz.y * 0.1, p.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
        }
        // Stones kicked onto the board tops and into the beds.
        for i in 0..<14 {
            var r = rng.fork(3000 + i)
            let sx: Float = r.chance(0.5) ? -1 : 1
            let p = V2(sx * r.float(bx + 0.06...w / 2 - 0.06), r.float(-d / 2 + 0.06...d / 2 - 0.06))
            AK.stone(&m, at: p, y: soilH(p) - 0.004, size: r.float(0.012...0.035), rng: &r)
        }
        // Weeds: dandelion-style tufts in the path edges and bed margins.
        for i in 0..<7 {
            var r = rng.fork(4000 + i)
            let inPath = i < 4
            let sx: Float = r.chance(0.5) ? -1 : 1
            let p = inPath ? V2(sx * r.float(px - 0.06...px - 0.02), r.float(-d / 2 + 0.1...d / 2 - 0.1))
                           : V2(sx * r.float(bx + 0.06...bx + 0.2), r.float(-d / 2 + 0.1...d / 2 - 0.1))
            let y = inPath ? gravelH(p) : soilH(p)
            AK.weed(&m, at: V3(p.x, y - 0.004, p.y), height: r.float(0.03...0.05), count: 12, rng: &r, material: r.chance(0.6) ? "grass.lawn" : "grass.dry")
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 30, material: gravel) { p in abs(p.x) < px ? gravelH(p) : soilH(p) }
        return AK.finish(&m, lite: lite, ao: 0.07)
    }
}
