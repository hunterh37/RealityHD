import simd
import Foundation

/// Worn patchy lawn tile, 2 x 2 m: a thin, unevenly mown sward on a worn meadow floor, broken by
/// bare compacted patches and a diagonal desire-line track trodden to dirt, with pebbles kicked up
/// along the track and a faded tennis ball left in the grass.
public struct WornPatchyLawn: RealAsset {
    public static let id = "worn-patchy-lawn"
    public static let summary = "Worn patchy lawn tile, 2 x 2 m: thin mown grass broken by bare compacted patches and a worn foot track."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 34, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.12, 2.0)
    /// Blade count over the tile before bare areas are removed.
    public var blades: Int = 2900
    /// Mown height (m).
    public var height: Float = 0.05
    /// Desire-line track half width (m).
    public var trackHalfWidth: Float = 0.16
    /// Blade material.
    public var grass: MaterialKey = "grass.lawn"
    /// Worn sward floor.
    public var floor: MaterialKey = "ground.meadow-worn"
    /// Bare compacted soil.
    public var bare: MaterialKey = "ground.dirt:5A4835"
    /// Pebbles.
    public var stone: MaterialKey = "ground.gravel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        let hx = size.x / 2, hz = size.z / 2
        let base = size.y - height - 0.012
        func h(_ x: Float, _ z: Float) -> Float { base + 0.006 * Noise.fbm(V3(x * 1.8, 0, z * 1.8), octaves: 2, seed: sd) }
        var m = Model(name: Self.id)
        GK.field(&m, w: size.x, d: size.z, edge: base, segments: 36, floor) { p in
            0.006 * Noise.fbm(V3(p.x * 1.8, 0, p.y * 1.8), octaves: 2, seed: sd)
        }
        // Track centre line z(x) and its wobble.
        let z0 = rng.float(-0.7 ... -0.4), z1 = rng.float(0.4...0.7)
        func trackZ(_ x: Float) -> Float { z0 + (z1 - z0) * (x + hx) / size.x + 0.08 * sin(x * 2.2 + 1) }
        func trackW(_ x: Float) -> Float { trackHalfWidth * (1 + 0.35 * Noise.perlin(V3(x * 3, 0, 0), seed: sd + 3)) }
        // Bare blobs: centre, radius, phase.
        var blobs: [(V2, Float, Float)] = []
        for k in 0..<5 {
            var r = rng.fork(100 + k)
            blobs.append((V2(r.float(-0.75...0.75), r.float(-0.75...0.75)), r.float(0.1...0.24), r.float(0...6)))
        }
        func blobR(_ b: (V2, Float, Float), _ a: Float) -> Float {
            b.1 * (1 + 0.28 * sin(a * 3 + b.2) + 0.14 * sin(a * 5 + b.2 * 2))
        }
        func isBare(_ x: Float, _ z: Float, pad: Float = 0) -> Bool {
            if abs(z - trackZ(x)) < trackW(x) - pad { return true }
            for b in blobs {
                let d = V2(x, z) - b.0
                if simd_length(d) < blobR(b, atan2(d.y, d.x)) - pad { return true }
            }
            return false
        }
        // Track: a soil layer following the ground.
        let steps = 40
        var trackOutline: [V2] = []
        for i in 0...steps { let x = -hx + 0.004 + Float(i) / Float(steps) * (size.x - 0.008); trackOutline.append(V2(x, trackZ(x) - trackW(x))) }
        for i in (0...steps).reversed() { let x = -hx + 0.004 + Float(i) / Float(steps) * (size.x - 0.008); trackOutline.append(V2(x, trackZ(x) + trackW(x))) }
        trackOutline = trackOutline.map { V2($0.x, min(hz - 0.004, max(-hz + 0.004, $0.y))) }
        GK.poly(&m, trackOutline, top: base + 0.004, bare, thick: 0.004)
        for b in blobs {
            let outline = (0..<28).map { i -> V2 in
                let a = Float(i) / 28 * 2 * .pi
                let p = b.0 + V2(cos(a), sin(a)) * blobR(b, a)
                return V2(min(hx - 0.004, max(-hx + 0.004, p.x)), min(hz - 0.004, max(-hz + 0.004, p.y)))
            }
            GK.poly(&m, outline, top: base + 0.004, bare, thick: 0.004)
        }
        // Thin, uneven sward: density falls toward bare edges.
        var s = Surface(material: grass)
        for k in 0..<blades {
            var r = rng.fork(1000 + k)
            let x = r.float(-hx + 0.01...hx - 0.01), z = r.float(-hz + 0.01...hz - 0.01)
            if isBare(x, z, pad: -0.02 * r.float()) { continue }
            let dens = 0.5 + 0.5 * Noise.fbm(V3(x * 3, 0, z * 3), octaves: 2, seed: sd + 9)
            if r.float() > dens + 0.35 { continue }
            var t = PlantKit.Tuft()
            t.count = 1; t.radius = 0.0001
            t.height = height * (0.6 + 0.4 * dens); t.heightRange = 0.5...1.05
            t.width = 0.0025...0.0045
            t.lean = 0.1...0.6; t.splay = 0
            t.curl = 0...0.6; t.twist = 0.5
            t.segments = 2; t.mown = true
            s.append(PlantKit.tuft(t, at: V3(x, h(x, z) + 0.003, z), rng: &r, material: grass, phase: phase))
        }
        s.positions = s.positions.map { p in V3(min(hx - 0.002, max(-hx + 0.002, p.x)), p.y, min(hz - 0.002, max(-hz + 0.002, p.z))) }
        s.recomputeNormals(weldSeams: false)
        m.add(s)
        // Pebbles kicked up along the track.
        for k in 0..<30 {
            var r = rng.fork(5000 + k)
            let x = r.float(-0.95...0.95) * hx
            let z = trackZ(x) + r.float(-1...1) * trackW(x) * 0.8
            guard abs(z) < hz - 0.02 else { continue }
            let sz = r.float(0.006...0.016)
            var g = Prim.superellipsoid(V3(sz * 1.4, sz * 0.6, sz), exponent: 2.6, subdivisions: 1, material: stone)
            g.uvs = g.uvs.map { $0 * 4.7 }; g.computeTangents()
            m.add(g, Xform(translation: V3(x, base + 0.006, z), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
        }
        // A faded tennis ball left in the grass.
        let bx: Float = 0.55, bz: Float = -0.62
        m.add(Prim.superellipsoid(V3(0.067, 0.067, 0.067), exponent: 2, subdivisions: 4, material: "fabric.wool:C9D14A"),
              Xform(translation: V3(bx, h(bx, bz) + 0.024, bz)))
        PlantKit.finish(&m)
        groundAO(&m, height: size.y, floor: 0.55)
        var lite = Model(name: Self.id)
        for x in m.surfaces where x.material != grass { lite.add(x) }
        return LODModel(levels: [m, lite], switchDistances: [12])
    }
}
