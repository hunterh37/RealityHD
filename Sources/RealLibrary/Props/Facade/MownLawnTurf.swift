import simd
import Foundation

/// Mown lawn turf tile, 2 x 2 m: a cut soil base, a thatch mat and ~3000 blunt-cut blades laid in
/// alternating mower stripes (each 0.5 m pass leans the other way, so the bands read light and dark),
/// with a few daisies the mower missed.
public struct MownLawnTurf: RealAsset {
    public static let id = "mown-lawn-turf"
    public static let summary = "Mown lawn turf tile, 2 x 2 m: cut blades in alternating mower stripes over thatch and a cut soil edge."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.12, 2.0)
    /// Blade count over the tile.
    public var blades: Int = 2200
    /// Mown height (m).
    public var height: Float = 0.055
    /// Mower stripe width (m).
    public var stripe: Float = 0.5
    /// Blade material.
    public var grass: MaterialKey = "grass.lawn"
    /// Thatch mat material.
    public var thatch: MaterialKey = "grass.lawn-thatch"
    /// Thatch tints for the light and dark mower stripes.
    public var stripeThatch: [MaterialKey] = ["grass.lawn-thatch:76A052", "grass.lawn-thatch:577F3C"]
    /// Soil base material.
    public var soil: MaterialKey = "ground.dirt:4A3626"
    /// Daisies left by the mower.
    public var daisies: Int = 9
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        let hx = size.x / 2, hz = size.z / 2
        let base = size.y - height - 0.004
        func h(_ x: Float, _ z: Float) -> Float { base + 0.004 * Noise.fbm(V3(x * 2, 0, z * 2), octaves: 2, seed: sd) }
        var m = Model(name: Self.id)
        GK.field(&m, w: size.x, d: size.z, edge: base - 0.004, segments: 8, soil) { _ in 0 }
        // Thatch mat in 4 x 4 cells with turned UVs so the texture does not repeat.
        let cells = 4, cs = size.x / Float(cells)
        for cx in 0..<cells { for cz in 0..<cells {
            let ox = -hx + (Float(cx) + 0.5) * cs, oz = -hz + (Float(cz) + 0.5) * cs
            var q = Prim.terrain(size: V2(cs, cs), segments: 6, material: stripeThatch[(cz * cells / max(1, Int(size.z / stripe))) % 2 == 0 ? 0 : 1]) { p in h(p.x + ox, p.y + oz) + 0.001 }
            let turn = rng.int(0...3), off = V2(rng.float(0...7), rng.float(0...7))
            q.uvs = q.uvs.map { uv in var r = uv; for _ in 0..<turn { r = V2(-r.y, r.x) }; return r + off }
            q.positions = q.positions.map { $0 + V3(ox, 0, oz) }
            q.computeTangents()
            m.add(q)
        }}
        // Blades per stripe; each pass leans the other way.
        let bands = max(1, Int(size.z / stripe))
        let perBand = blades / bands
        for b in 0..<bands {
            var r = rng.fork(b)
            let z0 = -hz + Float(b) * stripe
            var s = Surface(material: grass)
            for _ in 0..<perBand {
                var t = PlantKit.Tuft()
                t.count = 1; t.radius = 0.0001
                t.height = height; t.heightRange = 0.6...1.15
                t.width = 0.0028...0.0048
                t.lean = 0.05...0.35; t.splay = 0
                t.curl = 0...0.4; t.twist = 0.5
                t.segments = 2; t.mown = true
                let x = r.float(-hx + 0.01...hx - 0.01), z = z0 + r.float(0.008...(stripe - 0.008))
                s.append(PlantKit.tuft(t, at: V3(x, h(x, z), z), rng: &r, material: grass, phase: phase))
            }
            let dir: Float = b % 2 == 0 ? 1 : -1
            s.positions = s.positions.map { p in
                let up = max(0, p.y - h(p.x, p.z))
                return V3(min(hx - 0.002, max(-hx + 0.002, p.x)), p.y - up * 0.15, min(hz - 0.002, max(-hz + 0.002, p.z + dir * up * 0.55)))
            }
            s.recomputeNormals(weldSeams: false)
            m.add(s)
        }
        // Daisies standing just above the cut.
        for k in 0..<daisies {
            var r = rng.fork(900 + k)
            let x = r.float(-0.9...0.9) * hx, z = r.float(-0.9...0.9) * hz
            let y = h(x, z) + height * 0.85
            m.add(Prim.tube([V3(x, h(x, z), z), V3(x + 0.003, y, z)], radii: [0.0012, 0.001], sides: 5, seamTile: 0.05, material: "plant.stem"))
            m.add(Prim.cylinder(radius: 0.01, height: 0.0012, bevel: 0.0003, segments: 12, material: "plastic.matte:F4F2EA"),
                  Xform(translation: V3(x + 0.003, y, z), rotation: simd_quatf(degrees: r.float(-15...15), axis: V3(1, 0, 0))))
            m.add(Prim.superellipsoid(V3(0.006, 0.003, 0.006), exponent: 2, subdivisions: 1, material: "plastic.matte:E2B21C"), Xform(translation: V3(x + 0.003, y + 0.0025, z)))
        }
        PlantKit.finish(&m)
        groundAO(&m, height: size.y, floor: 0.55)
        var lite = Model(name: Self.id)
        for s in m.surfaces where s.material != grass { lite.add(s) }
        return LODModel(levels: [m, lite], switchDistances: [12])
    }
}
