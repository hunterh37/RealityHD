import simd
import Foundation

/// Clover and wildflower lawn tile, 2 x 2 m: a relaxed-mow English lawn left to 100-150 mm, thick with
/// white clover (trefoil leaves and white globe heads), common daisies, creeping buttercup and purple
/// self-heal over a thatch mat and soil base.
public struct CloverWildflowerLawn: RealAsset {
    public static let id = "clover-wildflower-lawn"
    public static let summary = "Clover and wildflower lawn tile, 2 x 2 m: unmown lawn grass with white clover, daisies, buttercups and self-heal."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.25, 2.0)
    /// Grass blades over the tile.
    public var blades: Int = 1400
    /// Grass height (m).
    public var height: Float = 0.12
    /// Clover plants (each 3-5 trefoil leaves).
    public var clovers: Int = 56
    /// Flower counts: daisy, buttercup, self-heal.
    public var daisies = 30, buttercups = 16, selfheal = 12
    /// Blade material.
    public var grass: MaterialKey = "grass.lawn"
    /// Thatch mat.
    public var thatch: MaterialKey = "grass.lawn-thatch:5E8A40"
    /// Soil base.
    public var soil: MaterialKey = "ground.dirt:4A3626"
    /// Clover leaf.
    public var leaf: MaterialKey = "flower.petal:3F7A2E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        let hx = size.x / 2, hz = size.z / 2, base: Float = 0.06
        func h(_ x: Float, _ z: Float) -> Float { base + 0.008 * Noise.fbm(V3(x * 2, 0, z * 2), octaves: 2, seed: sd) }
        var m = Model(name: Self.id)
        // Flat elliptical blade (leaflet, petal or ray disc): 8-tri fan, both faces.
        func disc(_ c: V3, _ rx: Float, _ rz: Float, _ q: simd_quatf, _ mat: MaterialKey) {
            var d = Surface(material: mat)
            d.add(c, q.act(.up), V2(0.5, 0.5))
            for k in 0..<8 {
                let a = Float(k) / 8 * 2 * .pi
                d.add(c + q.act(V3(cos(a) * rx, 0, sin(a) * rz)), q.act(.up), V2(0.5 + cos(a) * 0.5, 0.5 + sin(a) * 0.5))
            }
            for k in 0..<8 { let a = UInt32(1 + k), b = UInt32(1 + (k + 1) % 8); d.indices += [0, b, a] }
            d.uvs = d.uvs.map { $0 * (2 * max(rx, rz)) }
            m.add(d)
        }
        GK.field(&m, w: size.x, d: size.z, edge: base - 0.005, segments: 8, soil) { _ in 0 }
        let cells = 4, cs = size.x / Float(cells)
        for cx in 0..<cells { for cz in 0..<cells {
            let ox = -hx + (Float(cx) + 0.5) * cs, oz = -hz + (Float(cz) + 0.5) * cs
            var q = Prim.terrain(size: V2(cs, cs), segments: 6, material: thatch) { p in h(p.x + ox, p.y + oz) + 0.001 }
            let turn = rng.int(0...3), off = V2(rng.float(0...7), rng.float(0...7))
            q.uvs = q.uvs.map { uv in var r = uv; for _ in 0..<turn { r = V2(-r.y, r.x) }; return r + off }
            q.positions = q.positions.map { $0 + V3(ox, 0, oz) }
            q.computeTangents()
            m.add(q)
        }}
        // Grass in loose tufts.
        var gs = Surface(material: grass)
        for k in 0..<(blades / 6) {
            var r = rng.fork(k)
            var t = PlantKit.Tuft()
            t.count = 6; t.radius = 0.02
            t.height = height; t.heightRange = 0.55...1.2
            t.width = 0.003...0.005
            t.lean = 0.1...0.45; t.splay = 0.4
            t.curl = 0.2...0.9; t.twist = 0.6; t.segments = 2; t.columns = 2
            let x = r.float(-hx + 0.03...hx - 0.03), z = r.float(-hz + 0.03...hz - 0.03)
            gs.append(PlantKit.tuft(t, at: V3(x, h(x, z), z), rng: &r, material: grass, phase: phase))
        }
        gs.positions = gs.positions.map { V3(min(hx - 0.002, max(-hx + 0.002, $0.x)), $0.y, min(hz - 0.002, max(-hz + 0.002, $0.z))) }
        gs.recomputeNormals(weldSeams: false)
        m.add(gs)
        // White clover: creeping runs of trefoils, three heart-shaped leaflets on a petiole, pale chevron.
        for k in 0..<clovers {
            var r = rng.fork(2000 + k)
            let x = r.float(-0.95...0.95) * hx, z = r.float(-0.95...0.95) * hz
            for _ in 0..<r.int(3...5) {
                let p = V2(x + r.float(-0.05...0.05), z + r.float(-0.05...0.05))
                let y = h(p.x, p.y) + r.float(0.03...0.07), yaw = r.float(0...6.28)
                for l in 0..<3 {
                    let a = yaw + Float(l) * 2.094
                    let c = V3(p.x + cos(a) * 0.008, y + 0.001, p.y + sin(a) * 0.008)
                    disc(c, 0.008, 0.0065, simd_quatf(angle: -a, axis: .up) * simd_quatf(degrees: r.float(-12...12), axis: V3(1, 0, 0)), leaf)
                }
            }
            if r.chance(0.6) {
                let y = h(x, z) + r.float(0.09...0.14)
                m.add(Prim.tube([V3(x, h(x, z), z), V3(x + 0.004, y, z)], radii: [0.0012, 0.001], sides: 4, seamTile: 0.05, material: "plant.stem"))
                m.add(Prim.superellipsoid(V3(0.02, 0.018, 0.02), exponent: 2, subdivisions: 1, material: "flower.petal:F1EEDF"),
                      Xform(translation: V3(x + 0.004, y + 0.006, z)))
            }
        }
        func flower(_ k: Int, petals: MaterialKey, eye: MaterialKey?, r rad: Float, cup: Bool, tall: ClosedRange<Float>) {
            var r = rng.fork(5000 + k)
            let x = r.float(-0.92...0.92) * hx, z = r.float(-0.92...0.92) * hz
            let y = h(x, z) + r.float(tall)
            m.add(Prim.tube([V3(x, h(x, z), z), V3(x + 0.005, (y + h(x, z)) / 2, z), V3(x + 0.003, y, z)], radii: [0.0014, 0.0012, 0.001], sides: 4, seamTile: 0.05, material: "plant.stem"))
            let tilt = simd_quatf(degrees: r.float(-20...20), axis: V3(1, 0, 0)) * simd_quatf(degrees: r.float(-20...20), axis: V3(0, 0, 1))
            if cup {
                for pI in 0..<5 {
                    let a = Float(pI) * 1.2566
                    disc(V3(x + 0.003, y, z) + tilt.act(V3(cos(a), 0.6, sin(a)) * rad * 0.55), rad * 0.5, rad * 0.42,
                         tilt * simd_quatf(angle: -a, axis: .up) * simd_quatf(degrees: 35, axis: V3(0, 0, 1)), petals)
                }
            } else {
                disc(V3(x + 0.003, y, z), rad, rad, tilt, petals)
            }
            if let e = eye { m.add(Prim.superellipsoid(V3(rad * 0.45, rad * 0.25, rad * 0.45), exponent: 2, subdivisions: 1, material: e), Xform(translation: V3(x + 0.003, y + 0.002, z), rotation: tilt)) }
        }
        for k in 0..<daisies { flower(k, petals: "flower.petal:F6F4EC", eye: "flower.petal:E2B21C", r: 0.011, cup: false, tall: 0.07...0.13) }
        for k in 0..<buttercups { flower(100 + k, petals: "flower.petal:F2C81A", eye: nil, r: 0.009, cup: true, tall: 0.12...0.18) }
        // Self-heal: short purple-violet cylindrical spikes.
        for k in 0..<selfheal {
            var r = rng.fork(7000 + k)
            let x = r.float(-0.9...0.9) * hx, z = r.float(-0.9...0.9) * hz, y = h(x, z) + r.float(0.06...0.1)
            m.add(Prim.tube([V3(x, h(x, z), z), V3(x, y, z)], radii: [0.0016, 0.0014], sides: 4, seamTile: 0.05, material: "plant.stem"))
            m.add(Prim.superellipsoid(V3(0.012, 0.024, 0.012), exponent: 2.6, subdivisions: 1, material: "flower.petal:6E4A9A") { d in 1 + 0.12 * sin(d.y * 30) },
                  Xform(translation: V3(x, y + 0.012, z)))
        }
        PlantKit.finish(&m)
        groundAO(&m, height: size.y, floor: 0.55)
        var lite = Model(name: Self.id)
        for s in m.surfaces where s.material == thatch || s.material == soil { lite.add(s) }
        return LODModel(levels: [m, lite], switchDistances: [12])
    }
}
