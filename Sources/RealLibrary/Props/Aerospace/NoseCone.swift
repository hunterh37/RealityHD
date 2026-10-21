import simd
import Foundation

/// Tangent-ogive nose cone on the 1.25 m bus: white-painted composite shell in two halves with
/// riveted separation-seam straps, bare carbon tip section, aluminum stack ring with a bolt circle, an
/// access door and a steel pitot probe with a heat-tinted tip.
public struct NoseCone: RealAsset {
    public static let id = "nose-cone"
    public static let summary = "Ogive nose cone, 1.25 m base: painted composite shell with a carbon tip, aluminum stack ring at the base, pitot probe."
    public static let tags = ["prop", "aerospace", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 1.0, studio: true)

    /// Base diameter in meters.
    public var diameter: Float = 1.25
    /// Height including the pitot probe.
    public var height: Float = 1.2
    /// Shell paint.
    public var paint: MaterialKey = "metal.powder-white"
    /// Tip section.
    public var tip: MaterialKey = "composite.carbon"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let R = diameter / 2 - 0.004, ringH: Float = 0.05
        let probe: Float = 0.07, L = height - probe - ringH          // ogive length above the ring
        let rho = (R * R + L * L) / (2 * R)
        let r: (Float) -> Float = { y in
            let x = min(max(y - ringH, 0), L)
            return max(0, sqrt(max(0, rho * rho - x * x)) + R - rho)
        }
        let tipY = ringH + L * 0.8
        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 64 : 28, n = l == 0 ? 28 : 12
            m.add(stackRing(radius: R - 0.01, y: 0, height: ringH, proud: 0.014, segments: sg, material: "metal.aluminum-brushed"))
            m.add(Prim.lathe([V2(R - 0.012, 0.003), V2(0, 0.003)].reversed(), segments: sg, material: "metal.aluminum-brushed"))
            // Painted shell up to the tip joint, carbon above it, closed at the apex.
            var lower: [V2] = [], upper: [V2] = []
            for k in 0...n {
                let y = ringH + (tipY - ringH) * Float(k) / Float(n)
                lower.append(V2(r(y), y))
            }
            let nt = l == 0 ? 12 : 6
            for k in 0...nt {
                let y = tipY + (ringH + L - tipY) * Float(k) / Float(nt)
                upper.append(V2(k == nt ? 0 : r(y) + 0.0015, y))
            }
            m.add(Prim.lathe(lower, segments: sg, seamTile: 1, material: paint))
            m.add(Prim.lathe(upper, segments: sg, seamTile: 0.3, material: tip))
            // Tip joint band.
            m.add(Prim.torus(major: r(tipY) + 0.001, minor: 0.004, segments: sg, sides: 6, material: "metal.aluminum-brushed"),
                  Xform(translation: V3(0, tipY, 0)))
            // Separation seams: riveted strap down each side of the two halves.
            for a in [Float.pi / 2, -Float.pi / 2] {
                let hw = 0.02 / R
                m.add(revPatch(radius: r, a0: a - hw, a1: a + hw, y0: ringH + 0.002, y1: tipY - 0.01, lift: 0.004, thickness: 0.004,
                               nu: 1, nv: l == 0 ? 10 : 5, material: "metal.aluminum-brushed"))
                if l == 0 {
                    for p in resample(meridian(r, a: a, y0: ringH + 0.03, y1: tipY - 0.04, lift: 0.004, n: 16), spacing: 0.07) {
                        let d = V3(sin(a), 0, cos(a))
                        rivet(&m, at: p, normal: simd_normalize(d + V3(0, 0.4 * p.y, 0)), radius: 0.0045, height: 0.0025, segments: 6, material: "metal.steel")
                    }
                }
            }
            // Roll-reference quarters (black) on the lower shell, opposite the door.
            for q in [1, 3] {
                let a0 = Float(q) * .pi / 2 + 0.05
                m.add(revPatch(radius: r, a0: a0, a1: a0 + .pi / 2 - 0.1, y0: ringH + 0.004, y1: 0.42, lift: 0.0028, thickness: 0.002,
                               nu: l == 0 ? 16 : 6, nv: l == 0 ? 4 : 2, material: "metal.powdercoat:1C1C1E"))
            }
            // Access door on the front with four fasteners.
            let da: Float = 0.25
            m.add(revPatch(radius: r, a0: da - 0.18, a1: da + 0.18, y0: 0.18, y1: 0.36, lift: 0.0015, thickness: 0.002,
                           nu: l == 0 ? 6 : 2, nv: 2, material: "metal.powdercoat:D4D4D0"))
            if l == 0 {
                for (aa, yy) in [(da - 0.15, Float(0.2)), (da + 0.15, 0.2), (da - 0.15, 0.34), (da + 0.15, 0.34)] {
                    let d = V3(sin(aa), 0, cos(aa))
                    rivet(&m, at: d * (r(yy) + 0.0015) + V3(0, yy, 0), normal: d, radius: 0.006, height: 0.002, segments: 6, material: "metal.steel")
                }
                boltCircle(&m, radius: R + 0.004, y: ringH * 0.5, count: 20, phase: rng.float(0...0.1), size: 0.005, material: "metal.steel")
            }
            // Pitot probe: base fairing, boom, heat-tinted tip.
            let top = ringH + L
            m.add(Prim.lathe([V2(0.014, top - 0.02), V2(0.012, top + 0.005), V2(0.006, top + 0.02), V2(0.004, top + 0.06),
                              V2(0.0035, top + 0.06)], segments: 12, seamTile: 0.05, material: "metal.steel"))
            m.add(Prim.lathe([V2(0.0035, top + 0.06), V2(0.0032, top + probe - 0.003), V2(0.002, top + probe), V2(0, top + probe)],
                             segments: 10, seamTile: 0.05, material: "metal.heat-tint-cold"))
            groundAO(&m, height: 0.1)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [9])
    }
}
