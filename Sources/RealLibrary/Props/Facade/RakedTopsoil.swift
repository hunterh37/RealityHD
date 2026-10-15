import simd
import Foundation

/// Raked topsoil ground tile, 2 x 2 m: a fine tilth bed combed by a garden rake into parallel tine
/// ridges that wander slightly with each pull, crumb clods on the ridges and the stones the rake
/// dragged out lying in a loose windrow along one edge.
public struct RakedTopsoil: RealAsset {
    public static let id = "raked-topsoil"
    public static let summary = "Raked topsoil ground tile, 2 x 2 m: fine tilth combed into parallel rake-tine furrows with clods and small stones."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.12, 2.0)
    /// Rake tine spacing (m).
    public var tineSpacing: Float = 0.055
    /// Ridge height above the bed (m).
    public var ridge: Float = 0.014
    /// Soil material.
    public var soil: MaterialKey = "soil.potting:5C4433"
    /// Darker damp soil in the furrow bottoms.
    public var bed: MaterialKey = "soil.potting:3A2A1F"
    /// Stone material.
    public var stone: MaterialKey = "ground.gravel"
    /// Number of clods.
    public var clods: Int = 120
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        let hx = size.x / 2, hz = size.z / 2
        let top: Float = size.y * 0.82
        func h(_ x: Float, _ z: Float) -> Float {
            top + 0.008 * Noise.fbm(V3(x * 1.6, 0, z * 1.6), octaves: 3, seed: sd)
        }
        var m = Model(name: Self.id)
        GK.field(&m, w: size.x, d: size.z, edge: top, segments: 44, bed) { p in
            0.008 * Noise.fbm(V3(p.x * 1.6, 0, p.y * 1.6), octaves: 3, seed: sd) + 0.004 * Noise.fbm(V3(p.x * 14, 0, p.y * 14), octaves: 2, seed: sd + 9) - 0.003
        }
        // Tine ridges: each pull wanders a little; ridges thin out and taper at the tile edge.
        let rows = Int(size.z / tineSpacing)
        let prof: [V2] = [V2(-0.004, -0.017), V2(0.4, -0.009), V2(1, 0), V2(0.4, 0.009), V2(-0.004, 0.017)]
        for j in 0..<rows {
            var r = rng.fork(j)
            let z0 = -hz + (Float(j) + 0.5) * size.z / Float(rows)
            let pull = Float(j / 6)
            let ph = r.float(0...6.28)
            let rh = ridge * r.float(0.7...1.25)
            var path: [V3] = [], scales: [Float] = []
            let n = 12
            for i in 0...n {
                let x = -hx + 0.012 + Float(i) / Float(n) * (size.x - 0.024)
                let ang = 0.035 * sin(pull * 2.1 + 0.7)
                let z = min(hz - 0.014, max(-hz + 0.014, z0 + ang * x + 0.014 * sin(x * 1.3 + pull * 0.9) + 0.004 * sin(x * 7 + ph)))
                path.append(V3(x, h(x, z) - 0.002, z))
                scales.append(0.45 + 0.9 * (0.5 + 0.5 * Noise.fbm(V3(x * 4, Float(j) * 0.7, 0), octaves: 2, seed: sd + 5)))
            }
            let p2 = prof.map { V2($0.x == -0.004 ? -0.004 : $0.x * rh, $0.y) }
            m.add(Prim.sweep(p2, along: path, up: V3(0, 1, 0), scales: scales, material: soil))
        }
        // Crumb clods sitting on the ridges.
        for k in 0..<clods {
            var r = rng.fork(2000 + k)
            let x = r.float(-0.95...0.95) * hx, z = r.float(-0.95...0.95) * hz
            let s = r.float(0.012...0.034)
            var c = Prim.superellipsoid(V3(s * r.float(1...1.5), s * 0.7, s), exponent: 2.4, subdivisions: 1, material: soil) { d in
                1 + 0.18 * Noise.perlin(d * 3 + V3(Float(k), 0, 0), seed: sd + 7)
            }
            c.uvs = c.uvs.map { $0 * 3 }; c.computeTangents()
            m.add(c, Xform(translation: V3(x, h(x, z) + ridge * 0.6, z), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
        }
        // Stones dragged out by the rake, windrowed along the far edge.
        for k in 0..<34 {
            var r = rng.fork(4000 + k)
            let x = r.float(-0.92...0.92) * hx, z = hz - 0.05 - abs(r.float(-1...1) * r.float(0...1)) * 0.09
            let s = r.float(0.01...0.026)
            var g = Prim.superellipsoid(V3(s * r.float(1.1...1.6), s * 0.65, s), exponent: 2.6, subdivisions: 2, material: stone)
            g.uvs = g.uvs.map { $0 * 0.85 }; g.computeTangents()
            m.add(g, Xform(translation: V3(x, h(x, z) + s * 0.2, z), rotation: simd_quatf(degrees: r.float(0...360), axis: .up) * simd_quatf(degrees: r.float(-12...12), axis: V3(1, 0, 0))))
        }
        // A pale root fragment the tines pulled up.
        let root = (0..<6).map { i -> V3 in
            let t = Float(i) / 5
            return V3(0.35 + t * 0.22, h(0.4, hz - 0.2) + 0.006 + 0.004 * sin(t * 6), hz - 0.2 - t * 0.05 + 0.01 * sin(t * 9))
        }
        m.add(Prim.tube(root, radii: root.indices.map { 0.004 - Float($0) * 0.0005 }, sides: 6, seamTile: 0.05, material: "wood.deadwood"))
        groundAO(&m, height: size.y, floor: 0.5)
        return LODModel(m)
    }
}
