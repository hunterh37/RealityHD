import simd
import Foundation

/// Edwardian allotment plot in midwinter, 2 x 2 m: soil rough-dug in autumn and left in spits for the
/// frost to break, every clod rimed with white hoar frost on its upper face, a boot print in the dug
/// ground holding a frozen puddle skinned with cloudy ice, dead fat-hen and dock stubble standing
/// brown, and flints turned up by the spade.
public struct AllotmentFrostedWinterSoil: RealAsset {
    public static let id = "allotment-frosted-winter-soil"
    public static let summary = "Frosted winter allotment soil tile, 2 x 2 m: rough-dug clods rimed with hoar frost, frozen puddle in a footprint, dead weed stalks."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 36, distance: 2.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.12, 2.0)
    /// Soil depth at the tile edge (m).
    public var depth: Float = 0.03
    /// Dug soil material (clod faces).
    public var soil: MaterialKey = "soil.potting:4A3A2C"
    /// Frost-whitened soil surface between the clods.
    public var rimed: MaterialKey = "soil.potting:8E8984"
    /// Hoar frost material.
    public var frost: MaterialKey = "ground.snow:C4CAD0"
    /// Puddle ice material.
    public var ice: MaterialKey = "glass.frosted:9FB0C0"
    /// Dead stalk material.
    public var stalk: MaterialKey = "grass.dry"
    /// Clods.
    public var clods: Int = 52
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z
        let print = V2(rng.float(-0.3...0.3), rng.float(0.2...0.5))
        func bump(_ p: V2) -> Float {
            // Spade spits in rows along X.
            var h = 0.028 * pow(abs(sin(p.y * 7 + 0.3 * sin(p.x * 3))), 0.7) + 0.012 * Noise.ridged(V3(p.x * 5, 0, p.y * 5), octaves: 3, seed: sd)
            h += 0.005 * Noise.fbm(V3(p.x * 20, 0, p.y * 20), octaves: 2, seed: sd + 1)
            let q = (p - print) * V2(1 / 0.055, 1 / 0.14)
            h -= 0.03 * exp(-pow(simd_length_squared(q), 2))
            return h
        }
        func height(_ p: V2) -> Float {
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y)), k = max(0, min(1, e / 0.06))
            return depth + bump(p) * k * k * (3 - 2 * k)
        }
        var m = Model(name: Self.id)
        GTK.field(&m, w: w, d: d, edge: depth, segments: 54, rimed, uvScale: 1, bump: bump)
        // Ice skin in the boot print.
        GK.poly(&m, (0..<16).map { k in let a = Float(k) / 16 * 2 * .pi; return print + V2(cos(a) * 0.045, sin(a) * 0.12) },
                top: height(print) + 0.018, ice, thick: 0.003)
        var lite = Model(name: Self.id + "-lite")
        GTK.field(&lite, w: w, d: d, edge: depth, segments: 20, rimed, uvScale: 1, bump: bump)
        // Clods, each with a frost cap on its upper face.
        var placed = 0
        for k in 0..<(clods * 3) where placed < clods {
            var r = rng.fork(100 + k)
            let p = V2(r.float(-0.9...0.9), r.float(-0.9...0.9))
            if simd_length((p - print) * V2(1, 0.4)) < 0.1 { continue }
            placed += 1
            let s = r.float(0.05...0.095)
            let sz = V3(s, s * r.float(0.5...0.75), s * r.float(0.65...0.9))
            let ss = UInt32(r.int(0...90_000))
            var c = Prim.superellipsoid(sz, exponent: 2.6, subdivisions: 2, material: soil) { dir in 1 + 0.14 * Noise.fbm(dir * 2.2, octaves: 2, seed: ss) }
            c.uvs = c.positions.map { V2($0.x + $0.y * 0.5, $0.z - $0.y * 0.5) + V2(r.float(0...3), r.float(0...3)) }
            GTK.normalizeTexel(&c); c.recomputeNormals(weldSeams: true); c.computeTangents()
            var cap = c
            cap.material = frost
            cap.positions = cap.positions.map { $0 * 1.04 + V3(0, sz.y * 0.06, 0) }
            let tri = cap.indices.count / 3
            var keep: [UInt32] = []
            for t in 0..<tri {
                let a = cap.positions[Int(cap.indices[t * 3])], b = cap.positions[Int(cap.indices[t * 3 + 1])], cc = cap.positions[Int(cap.indices[t * 3 + 2])]
                if (a.y + b.y + cc.y) / 3 > sz.y * 0.46 { keep += [cap.indices[t * 3], cap.indices[t * 3 + 1], cap.indices[t * 3 + 2]] }
            }
            cap.indices = keep
            let x = Xform(translation: V3(p.x, height(p) + sz.y * 0.32, p.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up) * simd_quatf(degrees: r.float(-12...12), axis: V3(1, 0, 0)))
            m.add(c, x); m.add(cap, x)
        }
        // Frost dusting on the soil between clods.
        GTK.stones(&m, &rng, count: 60, hx: 0.95, hz: 0.95, size: 0.006...0.016, flat: 0.25...0.4, keys: [frost], sink: 0.2, surface: height)
        // Flints.
        GTK.stones(&m, &rng, count: 18, hx: 0.9, hz: 0.9, size: 0.03...0.06, keys: ["rock.river:B8B0A4", "rock.river:6A665E"], subdivisions: 1, exponent: 2.2, sink: 0.4, surface: height)
        // Dead weed stalks.
        for k in 0..<7 {
            var r = rng.fork(400 + k)
            let p = V2(r.float(-0.85...0.85), r.float(-0.85...0.85))
            for _ in 0..<r.int(2...4) {
                let b = V3(p.x + r.float(-0.02...0.02), height(p) - 0.005, p.y + r.float(-0.02...0.02))
                let hgt = r.float(0.025...0.045), lean = V3(r.float(-0.06...0.06), 0, r.float(-0.06...0.06))
                m.add(Prim.tube([b, b + V3(0, hgt * 0.5, 0) + lean * 0.3, b + V3(0, hgt, 0) + lean], radii: [0.003, 0.0024, 0.0012], sides: 5, seamTile: 0.05, material: stalk))
            }
        }
        return GTK.finish(&m, &lite, ao: 0.04, switchAt: 8)
    }
}
