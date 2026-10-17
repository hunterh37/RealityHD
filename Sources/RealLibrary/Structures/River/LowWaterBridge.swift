import simd
import Foundation

/// Abandoned Ozark low-water bridge, 14 x 3.6 m: a poured concrete slab 0.55 m thick over four 0.9 m
/// corrugated steel culvert pipes, sitting on the riverbed with the deck just under the surface. One end
/// has broken away into tilted slabs with rusty rebar sticking out; algae and silt stain the upper faces.
/// Structure runs across the river along Z. 2 LODs.
public struct LowWaterBridge: RealAsset {
    public static let id = "low-water-bridge"
    public static let summary = "Abandoned low-water bridge, 14 m: concrete slab over four corrugated culverts, one end broken into tilted slabs with rusty rebar, algae stained, 2 LODs."
    public static let tags = ["structure", "river", "concrete", "water"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 0.8)

    /// Span across the river (Z), deck width (X along the flow) and slab thickness.
    public var span: Float = 14
    public var width: Float = 3.6
    public var thickness: Float = 0.55
    /// Height of the deck top above the bed.
    public var deckHeight: Float = 1.2
    public var culverts = 4
    public var culvertDiameter: Float = 0.9
    /// Fraction of the span (from +Z end) broken off and collapsed.
    public var broken: Float = 0.28
    public var concrete: MaterialKey = "concrete.river-algae"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let intact = span * (1 - broken)
        let z0 = -span / 2, zBreak = z0 + intact
        // Intact slab, with a rough displaced break face.
        func slab(_ size: V3, _ x: Xform, detail: Bool) -> Surface {
            var s = Prim.roundedBox(size, radius: 0.04, bevelSegments: detail ? 2 : 1, material: concrete)
            if detail { s = s.subdivided() }
            let ns = UInt32(truncatingIfNeeded: seed) &+ UInt32(size.z * 100)
            s.displace { p, n in 0.025 * Noise.fbm(p * 4, octaves: 3, seed: ns) }
            return s.transformed(x)
        }
        let deckX = Xform(translation: V3(0, deckHeight - thickness / 2, (z0 + zBreak) / 2))
        m0.add(slab(V3(width, thickness, intact), deckX, detail: true))
        m1.add(slab(V3(width, thickness, intact), deckX, detail: false))
        // Headwalls: a footing under the slab along each edge.
        for sx: Float in [-1, 1] {
            let fx = Xform(translation: V3(sx * (width / 2 - 0.2), (deckHeight - thickness) / 2, (z0 + zBreak) / 2))
            let f = Prim.roundedBox(V3(0.4, deckHeight - thickness + 0.1, intact), radius: 0.03, bevelSegments: 1, material: concrete)
            m0.add(f.transformed(fx)); m1.add(f.transformed(fx))
        }
        // Culverts through the footing, along X (with the flow).
        let rc = culvertDiameter / 2
        for i in 0..<culverts {
            let z = z0 + intact * (Float(i) + 0.5) / Float(culverts)
            var pipe = Prim.lathe([V2(rc, -width / 2 - 0.15), V2(rc, width / 2 + 0.15), V2(rc - 0.012, width / 2 + 0.15), V2(rc - 0.012, -width / 2 - 0.15), V2(rc, -width / 2 - 0.15)],
                                  segments: 20, seamTile: 0.3, material: "metal.rust")
            // Corrugations: ripple the radius along the pipe.
            pipe.displace { p, n in 0.012 * sin(p.y * 2 * .pi / 0.068) * (abs(n.y) < 0.5 ? 1 : 0) }
            let px = Xform(translation: V3(0, rc + 0.02, z), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1)))
            m0.add(pipe.transformed(px))
            m1.add(Prim.lathe([V2(rc, -width / 2 - 0.15), V2(rc, width / 2 + 0.15)], segments: 10, seamTile: 0.3, material: "metal.rust").transformed(px))
        }
        // Collapsed end: 3 tilted slab chunks dropped onto the bed.
        var z = zBreak + 0.2
        let rest = span / 2 - zBreak
        for k in 0..<3 {
            let len = rest / 3 * rng.float(0.8...1.1)
            let tilt = simd_quatf(degrees: rng.float(-18...18), axis: V3(0, 0, 1)) * simd_quatf(degrees: (k % 2 == 0 ? 1 : -1) * rng.float(8...22), axis: V3(1, 0, 0))
            let w = width * rng.float(0.6...0.95)
            let cx = Xform(translation: V3(rng.float(-0.4...0.4), thickness / 2 + Float(2 - k) * 0.15, z + len / 2),
                           rotation: simd_quatf(degrees: rng.float(-15...15), axis: .up) * tilt)
            m0.add(slab(V3(w, thickness, len), cx, detail: true))
            m1.add(slab(V3(w, thickness, len), cx, detail: false))
            // Rebar sticking out of the broken faces.
            for _ in 0..<rng.int(4...7) {
                let a = cx.point(V3(rng.float(-w / 2...w / 2) * 0.8, rng.float(-0.15...0.15), (rng.chance(0.5) ? 1 : -1) * len / 2))
                let out = cx.rotation.act(V3(rng.float(-0.3...0.3), rng.float(-0.2...0.5), a.z > z + len / 2 ? 1 : -1))
                let b = a + simd_normalize(out) * rng.float(0.2...0.7) + V3(0, -rng.float(0...0.15), 0)
                m0.add(Prim.tube([a, (a + b) / 2 + V3(0, 0.03, 0), b], radii: [0.008, 0.008, 0.008], sides: 5, seamTile: 0.2, material: "metal.rebar", capEnd: true))
            }
            z += len + rng.float(0.05...0.3)
        }
        // Rebar hanging from the intact break face.
        for _ in 0..<6 {
            let a = V3(rng.float(-width / 2...width / 2) * 0.85, deckHeight - thickness * rng.float(0.2...0.8), zBreak)
            let b = a + V3(rng.float(-0.1...0.1), -rng.float(0.2...0.8), rng.float(0.1...0.4))
            m0.add(Prim.tube([a, a + V3(0, 0, 0.08), b], radii: [0.008, 0.008, 0.008], sides: 5, seamTile: 0.2, material: "metal.rebar", capEnd: true))
        }
        groundAO(&m0); groundAO(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [25])
    }
}
