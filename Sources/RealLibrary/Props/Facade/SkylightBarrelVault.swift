import simd
import Foundation

/// Barrel vault skylight: architectural facade customizer, contemporary, weathered. Parts: aluminium curb upstand, base flashing apron, barrel-vault glazing, arched glazing bars, ridge cap, end arch frames, cap screws.
public struct SkylightBarrelVault: RealAsset {
    public static let id = "skylight-barrel-vault"
    public static let summary = "Barrel vault skylight, 2.0 x 1.5 m: aluminium curb, arched glazing bars, curved glass, flashing apron."
    public static let tags = ["prop", "architecture", "facade", "roof", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 22, distance: 3.0)

    /// Overall size in meters (x length along the vault, y height, z span).
    public var size = V3(2.0, 0.8, 1.5)
    /// Curb upstand height in meters.
    public var curbHeight: Float = 0.28
    /// Number of glazing bays along the vault.
    public var bays = 6
    /// Frame material key.
    public var frame: MaterialKey = "metal.anodized-worn"
    /// Glass material key.
    public var glass: MaterialKey = "glass.clear"
    /// Flashing material key.
    public var flashing: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = size.x - 0.23, S = size.z - 0.23, ch = curbHeight
        let rise = size.y - ch - 0.025
        let half = S / 2 - 0.05
        let barH: Float = 0.016
        let R = (half * half + (rise - barH) * (rise - barH)) / (2 * (rise - barH))
        let cy = ch + (rise - barH) - R
        let t0 = asin(half / R)
        let segs = 7
        func pt(_ t: Float, _ r: Float) -> V3 { V3(0, cy + r * cos(t), r * sin(t)) }

        // Curb: four aluminium walls with a top cap and an inset lip.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(L, ch, 0.05), V3(0, ch / 2, e * (S / 2 - 0.025)), frame, r: 0.004)
            FA.box(&m, V3(0.05, ch, S - 0.02), V3(e * (L / 2 - 0.025), ch / 2, 0), frame, r: 0.004)
            FA.box(&m, V3(L + 0.02, 0.012, 0.075), V3(0, ch + 0.004, e * (S / 2 - 0.03)), frame, r: 0.003)
        }
        // Flashing apron: sloped sheet at the base of each long side, folded drip edge, hem and seam.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(L + 0.2, 0.008, 0.13), V3(0, 0.05, e * (S / 2 + 0.05)), flashing, r: 0.002, rot: FA.q(e * 10, FA.X))
            FA.box(&m, V3(L + 0.2, 0.02, 0.014), V3(0, 0.002 + 0.01, e * (S / 2 + 0.108)), flashing, r: 0.004)
            FA.box(&m, V3(L + 0.2, 0.012, 0.012), V3(0, 0.078, e * (S / 2 + 0.002)), flashing, r: 0.003)
            FA.box(&m, V3(0.012, 0.008, 0.12), V3(e * 0.55, 0.05 + 0.0, e * (S / 2 + 0.05)), flashing, r: 0.002, rot: FA.q(e * 10, FA.X))
        }
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.13, 0.008, S + 0.2), V3(e * (L / 2 + 0.05), 0.05, 0), flashing, r: 0.002, rot: FA.q(-e * 10, FA.Z))
            FA.box(&m, V3(0.014, 0.02, S + 0.2), V3(e * (L / 2 + 0.108), 0.012, 0), flashing, r: 0.004)
        }
        // Smooth arc band (extruded arc profile) used for glazing bars, pressure caps and glass.
        let n = 28
        func arcBand(x: Float, depth: Float, r0: Float, r1: Float, mat: MaterialKey, bevel: Float, tc: Float = t0) {
            var o: [V2] = []
            for i in 0...n { let t = -tc + 2 * tc * Float(i) / Float(n); o.append(V2(r0 * sin(t), cy + r0 * cos(t))) }
            for i in stride(from: n, through: 0, by: -1) { let t = -tc + 2 * tc * Float(i) / Float(n); o.append(V2(r1 * sin(t), cy + r1 * cos(t))) }
            m.add(Prim.extrude(o, depth: depth, bevel: bevel, bevelSegments: 1, material: mat),
                  Xform(translation: V3(x, 0, 0), rotation: FA.q(-90, FA.Y)))
        }
        for k in 0...bays {
            let x = -L / 2 + 0.03 + (L - 0.06) * Float(k) / Float(bays)
            let w: Float = (k == 0 || k == bays) ? 0.05 : 0.036
            arcBand(x: x, depth: w, r0: R, r1: R + barH, mat: frame, bevel: 0.002)
            arcBand(x: x, depth: w + 0.014, r0: R + barH - 0.001, r1: R + barH + 0.005, mat: "metal.aluminum-brushed", bevel: 0.0015, tc: t0 - 0.01)
        }
        // Curved glass: one smooth 6 mm arc shell per bay, seated between the bars.
        let bayW = (L - 0.06) / Float(bays)
        for k in 0..<bays {
            let x = -L / 2 + 0.03 + bayW * (Float(k) + 0.5)
            arcBand(x: x, depth: bayW - 0.034, r0: R + barH - 0.009, r1: R + barH - 0.003, mat: (k == 4 ? "glass.frosted" : glass), bevel: 0.001, tc: t0 - 0.02)
        }
        // Horizontal purlin bars along the vault at intervals (cross-glazing bars).
        for i in [Int]() {
            let tm = -t0 + 2 * t0 * Float(i) / Float(segs)
            let p = pt(tm, R + barH - 0.002)
            FA.box(&m, V3(L - 0.06, 0.008, 0.018), V3(0, p.y, p.z), frame, r: 0.002, rot: FA.q(tm * 180 / .pi, FA.X))
        }
        // End arch frames: thick closing plates with a curved head rail.
        for e: Float in [-1, 1] {
            var outline: [V2] = [V2(-half - 0.015, 0)]
            for i in 0...segs {
                let t = -t0 + 2 * t0 * Float(i) / Float(segs)
                let p = pt(t, R)
                outline.append(V2(p.z, p.y - ch - 0.002))
            }
            outline.append(V2(half + 0.015, 0))
            m.add(Prim.extrude(outline, depth: 0.022, bevel: 0.003, bevelSegments: 1, material: "metal.galvanized-aged"),
                  Xform(translation: V3(e * (L / 2 - 0.045), ch + 0.002, 0), rotation: FA.q(-90, FA.Y)))
        }
        // Ridge cap: rounded aluminium strip over the crown with end caps.
        let top = pt(0, R + barH + 0.003)
        FA.box(&m, V3(L - 0.02, 0.012, 0.05), V3(0, top.y + 0.004, 0), frame, r: 0.004)
        for e: Float in [-1, 1] { FA.box(&m, V3(0.02, 0.018, 0.058), V3(e * (L / 2 - 0.012), top.y + 0.003, 0), frame, r: 0.005) }
        // Cap screws along the curb cap and ridge, zinc.
        for e: Float in [-1, 1] {
            for k in 0..<4 {
                let x = -L / 2 + 0.08 + Float(k) * (L - 0.16) / 3
                FA.cylZ(&m, r: 0.006, h: 0.004, at: V3(x, ch + 0.010, e * (S / 2 - 0.03)), "metal.screw-zinc", bevel: 0.001, segments: 6)
            }
        }
        for k in 0..<5 {
            let x = -L / 2 + 0.1 + Float(k) * (L - 0.2) / 4
            m.add(Prim.cylinder(radius: 0.0055, height: 0.004, bevel: 0.001, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                  Xform(translation: V3(x, top.y + 0.010, 0)))
        }
        // Story detail: a leaf wedged against the upslope curb.
        let lx = rng.float(-0.5...0.5)
        m.add(Prim.superellipsoid(V3(0.07, 0.006, 0.05), exponent: 2, subdivisions: 6, material: "wood.cedar-weathered"),
              Xform(translation: V3(lx, ch + 0.0125, -(S / 2) + 0.12), rotation: FA.q(rng.float(0...90), FA.Y)))
        // Weathering: grime band on the curb cap, leaf litter and a zinc-streak drip on the apron.
        for i in 0..<3 {
            m.add(Prim.superellipsoid(V3(0.05, 0.004, 0.035), exponent: 2, subdivisions: 5, material: "wood.cedar-weathered"),
                  Xform(translation: V3(rng.float(-0.7...0.7), 0.058, S / 2 + 0.07 + Float(i % 2) * 0.01), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        FA.box(&m, V3(0.3, 0.002, 0.04), V3(0.2, ch + 0.0105, S / 2 - 0.03), "metal.rust-grime", r: 0.0005)
        groundAO(&m)
        return LODModel(m)
    }
}
