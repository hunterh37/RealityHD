import simd
import Foundation

/// Long meadow grass tile, 2 x 2 m: an uncut hay-meadow sward of tussocks up to ~35 cm with
/// flowering culms carrying seed heads to ~48 cm, last year's dry blades lodged at the base, all
/// over a thatch and leaf-litter floor on a soil slab.
public struct LongMeadowGrass: RealAsset {
    public static let id = "long-meadow-grass"
    public static let summary = "Long meadow grass tile, 2 x 2 m: dense tussocks up to 45 cm with seed heads and dry blades over thatch."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 26, distance: 2.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.5, 2.0)
    /// Tussock count.
    public var tussocks: Int = 64
    /// Leaf height of a tussock (m).
    public var leafHeight: Float = 0.33
    /// Green blade material.
    public var grass: MaterialKey = "grass.tall"
    /// Dead blade material.
    public var dry: MaterialKey = "grass.dry"
    /// Seed head material.
    public var seed: MaterialKey = "grass.seedhead"
    /// Floor material.
    public var floor: MaterialKey = "ground.meadow"
    /// Soil base.
    public var soil: MaterialKey = "ground.dirt:4A3626"
    public init() {}

    public func build(seed s0: UInt64) -> LODModel {
        var rng = SeededRNG(seed: s0)
        let phase = rng.float(0...6.28)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        let hx = size.x / 2, hz = size.z / 2
        let base: Float = 0.03
        func h(_ x: Float, _ z: Float) -> Float { base + 0.008 * Noise.fbm(V3(x * 2, 0, z * 2), octaves: 2, seed: sd) }
        var m = Model(name: Self.id)
        GK.field(&m, w: size.x, d: size.z, edge: base - 0.004, segments: 8, soil) { _ in 0 }
        m.add(Prim.terrain(size: V2(size.x - 0.004, size.z - 0.004), segments: 24, material: floor) { p in h(p.x, p.y) })
        var green = Surface(material: grass), dead = Surface(material: dry)
        var lite = Model(name: Self.id)
        // Tussocks on a jittered grid so the sward is even with gaps between crowns.
        let n = Int(Float(tussocks).squareRoot().rounded())
        for j in 0..<n { for i in 0..<n {
            var r = rng.fork(j * n + i)
            let x = -hx + (Float(i) + 0.5 + r.float(-0.4...0.4)) * size.x / Float(n)
            let z = -hz + (Float(j) + 0.5 + r.float(-0.4...0.4)) * size.z / Float(n)
            let c = V3(min(hx - 0.06, max(-hx + 0.06, x)), 0, min(hz - 0.06, max(-hz + 0.06, z)))
            let at = V3(c.x, h(c.x, c.z) - 0.002, c.z)
            var t = PlantKit.Tuft()
            t.count = r.int(17...23)
            t.height = leafHeight * r.float(0.75...1.1); t.radius = r.float(0.07...0.11)
            t.heightRange = 0.4...1
            t.width = 0.003...0.007
            t.lean = 0.08...0.35; t.splay = 0.45
            t.curl = 0.5...1.5
            t.segments = 3
            green.append(PlantKit.tuft(t, at: at, rng: &r, material: grass, phase: phase))
            var d = t
            d.count = r.int(5...9); d.height = leafHeight * 0.7; d.lean = 0.4...0.8; d.curl = 0.6...1.1; d.segments = 2
            dead.append(PlantKit.tuft(d, at: at, rng: &r, material: dry, phase: phase))
            if r.chance(0.8) {
                var cm = Model(name: "culm")
                addCulms(&cm, count: r.int(1...3), height: leafHeight * 0.72, rng: &r, phase: phase, stemMaterial: "plant.stem", seedMaterial: seed)
                for var s in cm.surfaces { s = s.transformed(Xform(translation: at)); s.positions = s.positions.map { p in V3(min(hx - 0.003, max(-hx + 0.003, p.x)), p.y, min(hz - 0.003, max(-hz + 0.003, p.z))) }; m.add(s) }
            }
            lite.add(PlantKit.cardTuft(count: 2, height: t.height * 1.1, width: t.height * 0.9, segments: 1,
                                       cells: [PlantKit.cell(1, cols: 2, rows: 2)], rng: &r, material: "grass.tall-card", phase: phase),
                     Xform(translation: at))
        }}
        // Fill between crowns: crossed blade cards of the same sward.
        var fill = Surface(material: "grass.tall-card")
        for k in 0..<150 {
            var r = rng.fork(7000 + k)
            let x = r.float(-0.94...0.94) * hx, z = r.float(-0.94...0.94) * hz
            let ht = leafHeight * r.float(0.55...0.95)
            fill.append(PlantKit.cardTuft(count: 3, height: ht, width: ht * 0.8, segments: 2,
                                          cells: [PlantKit.cell(1, cols: 2, rows: 2), PlantKit.cell(0, cols: 2, rows: 2)], rng: &r, material: "grass.tall-card", phase: phase),
                        Xform(translation: V3(x, h(x, z) - 0.002, z)))
        }
        clamp(&fill)
        m.add(fill)
        func clamp(_ s: inout Surface) {
            s.positions = s.positions.map { p in V3(min(hx - 0.003, max(-hx + 0.003, p.x)), max(base - 0.004, p.y), min(hz - 0.003, max(-hz + 0.003, p.z))) }
            s.recomputeNormals(weldSeams: false)
        }
        clamp(&green); clamp(&dead)
        m.add(green); m.add(dead)
        PlantKit.finish(&m)
        groundAO(&m, height: 0.18, floor: 0.45)
        for s in m.surfaces where s.material == floor || s.material == soil { lite.add(s) }
        PlantKit.finish(&lite)
        return LODModel(levels: [m, lite], switchDistances: [12])
    }
}
