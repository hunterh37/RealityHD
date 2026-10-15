import simd
import Foundation

/// Molehill disturbed lawn tile, 2 x 2 m: a mown English lawn broken by fresh conical heaps of fine
/// crumbly loam pushed up by a mole, one older settled heap greening over, and a raised surface run
/// ridge linking them, with soil crumbs spilled on the grass.
public struct MolehillDisturbedLawn: RealAsset {
    public static let id = "molehill-disturbed-lawn"
    public static let summary = "Molehill disturbed lawn tile, 2 x 2 m: mown lawn broken by conical heaps of fine loam pushed up by moles and a raised run ridge."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.2, 2.0)
    /// Grass tufts over the lawn.
    public var tufts: Int = 180
    /// Mown grass height (m).
    public var height: Float = 0.05
    /// Grass blade material.
    public var grass: MaterialKey = "grass.lawn"
    /// Thatch layer under the blades.
    public var thatch: MaterialKey = "grass.lawn-thatch:4E6E34"
    /// Fresh loam.
    public var loam: MaterialKey = "ground.dirt:3A2A1E"
    /// Older, dried and settled loam.
    public var oldLoam: MaterialKey = "ground.dirt:6E5A44"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2, base: Float = 0.05
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        // Heaps: centre, radius, height, fresh.
        let hills: [(V2, Float, Float, Bool)] = [
            (V2(-0.45, -0.35), 0.21, 0.13, true), (V2(0.35, 0.05), 0.18, 0.12, true),
            (V2(0.55, -0.6), 0.16, 0.1, true), (V2(-0.4, 0.55), 0.2, 0.06, false)]
        // Run ridge: a raised line between the heaps.
        let run: [V2] = [V2(-0.45, -0.35), V2(-0.1, -0.2), V2(0.35, 0.05), V2(0.5, -0.3), V2(0.55, -0.6)]
        func ridge(_ p: V2) -> Float {
            var best: Float = 9
            for i in 0..<(run.count - 1) {
                let a = run[i], b = run[i + 1], ab = b - a
                let t = max(0, min(1, simd_dot(p - a, ab) / simd_dot(ab, ab)))
                best = min(best, simd_length(p - (a + ab * t)))
            }
            return best < 0.06 ? 0.018 * (1 - best * best / 0.0036) : 0
        }
        func lawn(_ p: V2) -> Float {
            0.008 * Noise.fbm(V3(p.x * 2, 0, p.y * 2), octaves: 2, seed: sd) + ridge(p)
        }
        func hill(_ p: V2) -> (Float, Bool)? {
            for (c, r, hh, fresh) in hills {
                let d = simd_length(p - c)
                if d < r {
                    let n = 1 + 0.2 * Noise.fbm(V3(p.x * 18, 0, p.y * 18), octaves: 2, seed: sd + 3) + 0.18 * Noise.fbm(V3(p.x * 70, 0, p.y * 70), octaves: 2, seed: sd + 4)
                    let t = 1 - d / r
                    return (hh * pow(t, fresh ? 0.75 : 1.4) * n, fresh)
                }
            }
            return nil
        }
        GTK.field(&m, w: size.x, d: size.z, edge: base, segments: 36, thatch, uvScale: 2) { lawn($0) }
        // Heaps as lathe-free domes: heightfield patches in loam, sitting over the lawn.
        for (c, r, _, fresh) in hills {
            var s = Prim.terrain(size: V2(r * 2.1, r * 2.1), segments: 20, material: fresh ? loam : oldLoam) { q in
                let p = q + c
                guard let (y, _) = hill(p) else { return base + lawn(p) - 0.006 }
                return base + lawn(p) + y - 0.002
            }
            s.positions = s.positions.map { $0 + V3(c.x, 0, c.y) }
            // Round the square patch to a disc.
            let keep = s.positions.map { simd_length(V2($0.x, $0.z) - c) <= r * 1.02 }
            var idx: [UInt32] = []
            for t in stride(from: 0, to: s.indices.count, by: 3) {
                let a = s.indices[t], b = s.indices[t + 1], d = s.indices[t + 2]
                if keep[Int(a)] || keep[Int(b)] || keep[Int(d)] { idx += [a, b, d] }
            }
            s.indices = idx
            s.recomputeNormals(weldSeams: true); s.computeTangents()
            m.add(s)
        }
        var lite = m
        // Soil crumbs on the heaps and spilled around them.
        for (k, (c, r, _, fresh)) in hills.enumerated() {
            var r2 = rng.fork(800 + k)
            GTK.stones(&m, &r2, count: fresh ? 70 : 20, hx: r * 1.5, hz: r * 1.5, size: 0.009...0.026, flat: 0.5...0.8,
                       keys: [fresh ? loam : oldLoam, "ground.dirt:3E2E22"], subdivisions: 1, sink: 0.4, offset: V3(c.x, 0, c.y),
                       surface: { q in let p = q + c; return base + lawn(p) + (hill(p)?.0 ?? 0) })
        }
        // Mown grass tufts, kept off the fresh heaps; the old heap is greening at its foot.
        var gs = Surface(material: grass)
        var n = 0, tries = 0
        while n < tufts && tries < tufts * 3 {
            tries += 1
            var r = rng.fork(3000 + tries)
            let p = V2(r.float(-hx + 0.03...hx - 0.03), r.float(-hz + 0.03...hz - 0.03))
            if let (y, fresh) = hill(p), fresh || y > 0.035 { continue }
            n += 1
            var t = PlantKit.Tuft()
            t.count = 8; t.radius = 0.025; t.height = height; t.heightRange = 0.7...1.1
            t.width = 0.003...0.0045; t.lean = 0.05...0.3; t.splay = 0.4; t.segments = 2; t.columns = 2; t.mown = true
            gs.append(PlantKit.tuft(t, at: V3(p.x, base + lawn(p) + (hill(p)?.0 ?? 0), p.y), rng: &r, material: grass))
        }
        gs.positions = gs.positions.map { V3(min(hx - 0.002, max(-hx + 0.002, $0.x)), $0.y, min(hz - 0.002, max(-hz + 0.002, $0.z))) }
        gs.recomputeNormals(weldSeams: false)
        m.add(gs)
        PlantKit.finish(&m)
        groundAO(&m, height: 0.06, floor: 0.65)
        groundAO(&lite, height: 0.06, floor: 0.65)
        return LODModel(levels: [m, lite], switchDistances: [8])
    }
}
